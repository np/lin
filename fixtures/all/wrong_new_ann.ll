wrong_new_ann = proc(c : !Int)
  new/(fuse "42") [d : !Int, e]
  ( send d 1
  | fwd(!Int)(c,e))
