module learn/exception


effect resumable-exn
  ctl throw-resumable(message : string, need-resume : bool) : ()

fun try-resumable(action : () -> <resumable-exn,console|e> ()) : <console|e> ()
  with ctl throw-resumable(message, need-resume)
    println(message)
    if need-resume then resume(())
  action()

fun subtract-natural-number(x : int, y : int, default : int = 0) : resumable-exn int
  val result = x - y
  if result <= 0 then
    throw-resumable(x.show ++ " - " ++ y.show ++ " は自然数じゃないよ", default >= 1)
    default
  else
    result

pub fun example-subtract-natural-number()
  println("------------")
  println("2 - 1")
  try-resumable
    println("結果: " ++ subtract-natural-number(2, 1).show)
  println("------------")
  
  println("------------")
  println("2 - 3")
  try-resumable
    println("結果: " ++ subtract-natural-number(2, 3).show)
  println("------------")

  println("------------")
  println("2 - 3")
  try-resumable
    println("結果: " ++ subtract-natural-number(2, 3, 1).show)
  println("------------")