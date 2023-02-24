{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE Rank2Types            #-}
{-# LANGUAGE TemplateHaskell       #-}
module Ling.Proto
  -- Types
  ( Proto
  -- Lenses
  , chans
  , skel
  -- Operations
  , dotProto
  , prettyProto
  , prettyChanDecs
  , isEmptyProto
  , rmChans
  , substChans
  , chanSession
  , chanSessions
  , arrayProto
  , pureProto
  , mkProto
  , protoSendRecv
  , replProto
  , assertUsed
  , assertAbsent
  , assertRepl1
  , checkOrderedChans
  , checkSomeOrderChans
  , checkConflictingChans)
  where

import           Ling.Check.Base
import           Ling.Norm
import           Ling.Prelude
import           Ling.Print
import           Ling.Proto.Skel      (Skel, actS, prllActS, dotActS)
import qualified Ling.Proto.Skel      as Skel
import           Ling.Session
import           Ling.SubTerms

import qualified Data.Map             as Map
import qualified Data.Set             as Set
import           Prelude              hiding (log)

data Proto = MkProto { _chans  :: Map Channel RSession
                     , _skel   :: Skel Channel
                     }

$(makeLenses ''Proto)

prettyProto :: Proto -> [String]
prettyProto p = concat
  [[" channels:"]
  ,("   - " ++) <$> prettyChanDecs p
  ,if p ^. skel == ø then [] else
   " skeleton:"
   : p ^.. skel . prettied . indented 3]

-- toListOf chanDecs :: Proto -> [Arg Session]
chanDecs :: Fold Proto (Arg RSession)
chanDecs = chans . to m2l . each . to (uncurry Arg)

prettyChanDecs :: Proto -> [String]
prettyChanDecs = toListOf (chanDecs . prettied)

instance Semigroup Proto where
  -- Use (<>) to combine protocols from processes which are composed in
  -- **parallel** (namely tensor).
  -- If the processes are in sequence use dotProto instead.
  (<>) = combineProto TenK

instance Monoid Proto where
  mempty = MkProto ø ø

instance SubTerms Proto where
  subTerms = chans . each . subTerms

dotProto :: Op2 Proto
dotProto = combineProto SeqK

combineProto :: TraverseKind -> Op2 Proto
combineProto k proto0 proto1 =
  if Set.null common then
    MkProto (proto0^.chans <> proto1^.chans)
            (Skel.combineS k (proto0^.skel) (proto1^.skel))
  else
    error . unlines $ ["These channels are re-used:", pretty common]
  where
    common = keysSet (proto0^.chans) `Set.intersection` keysSet (proto1^.chans)

arrayProto :: TraverseKind -> [Proto] -> Proto
arrayProto k = foldr (combineProto k) ø

-- Not used
-- chanPresent :: Channel -> Getter Proto Bool
-- chanPresent c = chans . hasKey c

isEmptyProto :: Getter Proto Bool
isEmptyProto = chans . to Map.null

addChanOnly :: (Channel,RSession) -> Endom Proto
addChanOnly (c,s) = chans . at c ?~ s

rmChansOnly :: [Channel] -> Endom Proto
rmChansOnly cs = chans %~ deleteList cs

rmChans :: [Channel] -> Endom Proto
rmChans cs p =
  p & rmChansOnly cs
    & skel %~ Skel.prune (l2s cs)

substChans :: ([Channel], (Channel,RSession)) -> Endom Proto
{- This behavior is what reject:
  ten_par_par_seq = proc(c : [{},{}]) c[d,e] d{} e{}
   and also
  tensor2_tensor0_tensor0_sequence = proc(cd : [[], []]) cd[c,d] c[] d[]
substChans ([], (c,s)) p =
  p & addChanOnly (c,s)
    & skel %~ actS c
-}
substChans (cs, (c,s)) p =
  p & rmChansOnly cs
    & addChanOnly (c,s)
    & skel %~ Skel.subst (substMember (l2s cs, Skel.Act c) Skel.Act)

chanSession :: Channel -> Lens' Proto (Maybe RSession)
chanSession c = chans . at c

chanSessions :: [Channel] -> Proto -> [Maybe RSession]
chanSessions cs p = [ p ^. chanSession c | c <- cs ]

pureProto :: Channel -> Session -> Proto
pureProto c s = MkProto (l2m [(c,oneS s)]) (c `actS` ø)

mkProto :: TraverseKind -> [(Channel,Session)] -> Proto
mkProto k = arrayProto k . map (uncurry pureProto)

-- Update a protocol with a given list of `session transformers` induced by
-- `send` and `recv` session types.
-- Example:
--    protoSendRecv [(c0,sendS t0), (c1, recvS t1)] (pureProto c0 s0) ^. chans
--    ==
--    [(c0,sendS t0 s0), (c1, recvS t1 (endS # ()))]
protoSendRecv :: Monad m => [(Channel, EndoM m Session)] -> EndoM m Proto
protoSendRecv cfs p = do
  p' <- foldrM go p cfs
  pure $ p' & skel %~ prllActS (cfs ^.. each . _1)
  where
    go (c,f) p2 = do
        s' <- (p ^. chanSession c . endedRS) & rsession %%~ f
        pure $ addChanOnly (c, s') p2

assertRepl1 :: MonadError TCErr m => Proto -> Channel -> m ()
assertRepl1 proto c =
  case proto ^. chanSession c of
    Just s -> assert (has (rfactor . litR1) s) ["Unexpected replication on channel " ++ pretty c]
    _ -> pure ()

-- Make sure the channel is used.
-- When the session is ended we want to skip this check and allow the
-- the channel to be unused.
assertUsed :: MonadError TCErr m => Proto -> Channel -> m ()
assertUsed proto c = assert (_Just `is` s) ["Unused channel " ++ pretty c]
  where s = proto ^. chanSession c

assertAbsent :: MonadError TCErr m => Proto -> Channel -> m ()
assertAbsent proto c =
  assert (proto ^. chans . hasNoKey c)
    ["The channel " ++ pretty c ++ " has been re-used"]

checkConflictingChans :: MonadTC m => Proto -> Maybe Channel -> [Channel] -> m Proto
checkConflictingChans proto c cs =
  debugCheck (\res -> unlines $
    ["Checking channel conflicts for channels:"
    ,"  " ++ pretty cs ++ " to be replaced by " ++ pretty c
    ,"Input protocol:"
    ] ++ prettyProto proto ++
    ["Output protocol:"
    ] ++ prettyError prettyProto res) $
    (proto & skel %%~ Skel.check c cs)
    `catchError` (\err -> do
      debug err
      throwError . unlines $
        ["These channels should be used independently:", pretty (Comma (sort cs))]
    )

checkOrderedChans :: MonadTC m => Proto -> [Channel] -> m ()
checkOrderedChans proto cs = do
  debug . unlines $
    ["Checking channel ordering for:"
    ,"  " ++ pretty cs
    ,"Protocol:"
    ] ++ prettyProto proto ++
    ["Selected ordering:"
    ] ++ (my ^.. prettied . indented 2)
  assert (ref == my)
    ["These channels should be used in-order:", pretty (Comma cs)]
    where ref = cs `dotActS` ø
          my  = Skel.select (l2s cs) (proto^.skel)

checkSomeOrderChans :: MonadTC m => Proto -> Set Channel -> m ()
checkSomeOrderChans proto cs = do
  b <- view $ tcOpts.strictPar
  debug . unlines $
    ["Checking SOME channel ordering for:"
    ,"  " ++ pretty cs
    ,"Protocol:"
    ] ++ prettyProto proto ++
    ["Selected ordering:"
    ,"  " ++ pretty my]
  assert (not b || Just cs == my)
    ["These channels should be used in some order (not in parallel):", pretty (s2l cs)]
    where my = Skel.nonParallelChannelSet $ Skel.select cs (proto^.skel)

replProto :: TraverseKind -> RFactor -> Endom Proto
replProto k r p = p & chans . mapped %~ replRSession r
                    & skel %~ Skel.replS k r
