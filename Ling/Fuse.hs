{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE TemplateHaskell #-}
module Ling.Fuse where

import           Ling.Norm
import           Ling.Prelude
import           Ling.Proc
import           Ling.Print
import           Ling.Reduce
import           Ling.Rename
import           Ling.Scoped
import           Ling.SubTerms
import           Ling.Defs
import           Ling.Session
import           Ling.Subst

type Allocation = Term

-- isoPrism :: Prism s t a b -> Iso s t (Either s a) (Either b t)
-- isoPrism p pafb = p pafb

data AllocAnn
  = FusedAnn
  | FuseAnn Int
--  | Alloc
--  | Auto

data Fused =
  Fused { _fusedDefs :: !Defs
        , _fusedActs :: !(Order Act)
        }

instance Dottable Fused where
  Fused defs acts `dotP` proc1 = defs `dotP` acts `dotP` proc1

defaultFusion, autoFusion :: AllocAnn -- [Allocation] -> Maybe [Allocation]
defaultFusion = FusedAnn
autoFusion = defaultFusion

makePrisms ''AllocAnn

instance Semigroup AllocAnn where
  FusedAnn <> x = x
--x <> FusedAnn = x
  x <> _        = x

instance Monoid AllocAnn where
  mempty = defaultFusion

_AllocAnn :: Prism' Allocation AllocAnn
_AllocAnn = prism' con pat where
  con = \case
    FusedAnn  -> mkPrimOp (Name "fused") []
    FuseAnn i -> mkPrimOp (Name "fuse" ) [litTerm . integral # i]
    -- Alloc   -> mkPrimOp (Name "alloc") []
    -- Auto    -> mkPrimOp (Name "auto" ) []
  pat = \case
    Def _ (Name "fused") []  -> Just FusedAnn
    Def _ (Name "fuse" ) [i] -> i ^? litTerm . integral . re _FuseAnn
    Def _ (Name "alloc") []  -> Just (FuseAnn 0) -- TEMPORARY, `alloc` is defined as `fuse 0`
    Def _ (Name "auto" ) []  -> Just autoFusion
    t                        -> trace ("[WARNING]: Unexpected allocation annotation: " ++ ppShow t) Nothing

doFuse :: [Allocation] -> Maybe [Allocation]
doFuse anns =
  case anns ^. each . _AllocAnn of
    FusedAnn  -> Just anns
    FuseAnn i
      | i > 0     -> Just $ anns & each . _AllocAnn . _FuseAnn %~ pred
      | otherwise -> Nothing

type NU = [ChanDec] -> Act

type Fuse2 a b = NU -> Reduced ChanDec -> a -> Reduced ChanDec -> b -> Fused
type Fuse2' a = Fuse2 a a

fuseDot :: Defs -> Op2 Proc
fuseDot defs = \case
  Act (Nu anns0 pat)
    | anns1 <- reduceS $ Scoped defs ø anns0
    , Just anns2 <- doFuse anns1 ->
    case pat of
      ArrayP k pats
        | cs <- pats ^. _Chans
        , [c, d] <- reduce . Scoped defs ø <$> cs
        -> fuseProc defs . fuse2Chans (Nu anns2 . ArrayP k . (_Chans #)) c d
      ChanP cd0 ->
        let cd = reduce $ Scoped defs ø cd0 in
        fuseProc defs . fuse1Chan (Nu anns2 . ArrayP SeqK . (_Chans #)) cd
      _ -> error . unlines $ [ "Unsupported fusion for " ++ pretty pat
                             , "Hint: fusion can be disabled using `new/alloc` instead of `new`" ]
  proc0@Replicate{} -> (fuseProc defs proc0 `dotP`) . fuseProc defs
  proc0 -> (proc0 `dotP`) . fuseProc defs

fuseProc :: Defs -> Endom Proc
fuseProc defs = \case
  proc0 `Dot` proc1 -> fuseDot defs proc0 proc1

  Act act -> fuseDot defs (Act act) ø

  -- go recurse...
  LetP defs0 proc0 -> defs0 `dotP` fuseProc (defs <> defs0) proc0
  Procs procs -> Procs $ procs & each %~ fuseProc defs
  Replicate k t x proc0 -> mkReplicate k t x $ fuseProc defs proc0

-- not used
fuseChanDecs :: NU -> [(Reduced ChanDec, Reduced ChanDec)] -> Endom Proc
fuseChanDecs _  []           = id
fuseChanDecs nu ((c0,c1):cs) = fuse2Chans nu c0 c1 . fuseChanDecs nu cs

fuseSendRecv :: Fuse2 Term VarDec
fuseSendRecv nu c0 e c1 (Arg x mty) = Fused (aDef x mty e) (Order [nu [f c0, f c1]])
  where
    f rc = (rc ^. reduced . scoped) & cdSession . _Just . rsession
                                    %~ substScoped . (rc ^. reduced $>)
                                     . sessionStep {-TODO defs-} (mkVar x)

two :: ([a] -> b) -> a -> a -> b
two f x y = f [x, y]

{-
new[c : {A,B}, d : [~A,~B]]

new[c0 : A, d0 : ~A]
new[c1 : B, d1 : ~B]
-}

fuse2Pats :: Fuse2' CPatt
fuse2Pats nu _c0 pat0 _c1 pat1
  | Just (_, cs0) <- pat0 ^? _ArrayCs
  , Just (_, cs1) <- pat1 ^? _ArrayCs = Fused ø (Order $ zipWith (two nu) cs0 cs1)
  | otherwise                         = error "Fuse.fuse2Pats unsupported split"

fuse2Acts :: Fuse2' Act
fuse2Acts nu c0 act0 c1 act1 =
  case (act0, act1) of
    (Split _c0 pat0, Split _c1 pat1) -> fuse2Pats nu c0 pat0 c1 pat1
    (Send _d0 _ e, Recv _d1 arg) -> fuseSendRecv nu c0 e c1 arg
    (Recv _d0 arg, Send _d1 _ e) -> fuseSendRecv nu c1 e c0 arg
              -- By typing, (c0,c1) and (d0,d1) should be equal, we could assert that for debugging.
    (Split{}, _)    -> error "fuse2Acts/Split: IMPOSSIBLE `split` should match another `split`"
    (Send{}, _)     -> error "fuse2Acts/Send: IMPOSSIBLE `send` should match `recv`"
    (Recv{}, _)     -> error "fuse2Acts/Recv: IMPOSSIBLE `recv` should match `send`"
    (Nu{}, _)       -> error "fuse2Acts/Nu: IMPOSSIBLE `new` does not consume channels"
    (Ax{}, _)       -> error "fuse2Acts/Ax: should be expanded before"
    (At{}, _)       -> error "fuse2Acts/At: should be expanded before"

fuse1Chan :: NU -> Reduced ChanDec -> Endom Proc
fuse1Chan nu cd p0 =
  case mact0 of
    Nothing -> p0 -- error "fuse1Chan: mact0 is Nothing"
    Just actA ->
      case mact1 of
        Nothing ->
          error $ "fuse1Chan: cannot find " ++ pretty c ++ " in " ++ pretty p1
        Just actB ->
          p1 & fetchActProc hasC .~ toProc (fuse2Acts nu cd actA cd actB)
  where
    c = cd ^. reduced . scoped . cdChan
    hasC :: Set Channel -> Bool
    hasC fc = fc ^. hasKey c

    -- TODO fuse into one traversal
    mact0 = p0 ^? fetchActProc hasC . _Act
    p1    = p0 &  fetchActProc hasC .~ ø

    mact1 = p1 ^? fetchActProc hasC . _Act

fuse2Chans :: NU -> Reduced ChanDec -> Reduced ChanDec -> Endom Proc
fuse2Chans nu cd0 cd1 p0 =
  case mact0 of
    Nothing -> p0 -- error "fuse2Chans: mact0 is Nothing"
    Just actA ->
      let
        (cdA, cdB) = if setOf freeChans actA ^. hasKey c0 then (cd0, cd1) else (cd1, cd0)
        cB = cdB ^. reduced . scoped . cdChan
        predB :: Set Channel -> Bool
        predB fc = fc ^. hasKey cB
        mactB = p0 {- was p1 -} ^? {-scoped .-} fetchActProc predB . _Act
      in
      case mactB of
        Nothing ->
          error $ "fuse2Chans: cannot find " ++ pretty cB ++ " in " ++ pretty p0
        Just actB ->
          p0 & fetchActProc predA .~ toProc (fuse2Acts nu cdA actA cdB actB)
             & fetchActProc predB .~ ø
  where
    c0 = cd0 ^. reduced . scoped . cdChan
    c1 = cd1 ^. reduced . scoped . cdChan
    predA :: Set Channel -> Bool
    predA fc = fc ^. hasKey c0 || fc ^. hasKey c1

    -- TODO fuse into one traversal
    mact0 = p0 ^? {-scoped .-} fetchActProc predA . _Act
    -- p1    = p0 &  {-scoped .-} fetchActProc predA .~ ø

-- This is quite similar to Sequential.transTermProc.
fuseTermProc :: Defs -> Endom Term
fuseTermProc gdefs0 tm0
  | tm1 <- reduce (Scoped gdefs0 ø tm0) ^. reduced
  , Proc cs proc0 <- tm1 ^. scoped
  , proc1 <- reduce (Scoped gdefs0 ø () *> tm1 $> proc0) ^. reduced
  = mkLetS $ tm1 $> Proc cs (
      proc1 ^. ldefs `dotP`
      fuseProc (gdefs0 <> tm1 ^. ldefs <> proc1 ^. ldefs)
               (proc1 ^. scoped))
  | otherwise
  = tm0

fuseProgram :: Defs -> Endom Program
fuseProgram pdefs = transProgramTerms $ fuseTermProc . (pdefs <>)
{-
fuse2Chans c0 c1 p0 =
  p0 & partsOf (scoped . procActsChans (l2s [c0,c1])) %~ f

  where f [] = []
        f (act0 : acts)
          | c0 `member` freeChans act0 = g act0 acts c0
          | otherwise              = g act0 acts c1
        g act0 acts cA =
          let (acts0,act1:acts1) = span (member cA . freeChans) acts
              (act0',act1')      = fuse2Acts (act0, act1)
          in act0' : acts0 ++ act1' : acts1
-}
