effect ask<a>
  ctl ask() : a

val ask-handler2 = handler
  ctl ask() resume("ask value")

fun ask-handler(value : a, action : () -> <ask<a>|e> r) : e r
  with ctl ask()
    resume(value)
  action()

fun example-ask()
  with ask-handler2
  ask()

fun example-ask2()
  with ask-handler("ask value 2")
  ask()

effect emit<a>
  ctl emit(v : a) : ()

val emit-handler2 = handler
  ctl emit(message)
    println("Emit: " ++ message)
    resume(())

fun emit-handler(action : () -> <emit<string>,console|e> r) : <console|e> r
  with ctl emit(message)
    println("Emit " ++ message)
    resume(())
  action()

fun example-emit()
  with emit-handler
  emit("Hello")

fun ask-emit() : <ask<a>, emit<a>, console> ()
  println("Start")
  val v = ask()
  emit(v)
  println("End")

pub fun example-ask-emit2()
  with ask-handler2
  with emit-handler
  ask-emit()

pub fun example-ask-emit()
  with ask-handler("Ask Value")
  with emit-handler()
  ask-emit()

pub fun example-ask-emit3()
  ask-handler("Ask Value", fn ()
    emit-handler(fn ()
      ask-emit()
    )
  )

pub fun example-ask-emit4()
  (handler {
    ctl ask() 
      resume("Ask Value")
  }) fn () {
    (handler {
      ctl emit(message)
        println("Emit " ++ message)
        resume(())
    }) fn () {
      println("Start")
      val v = ask()
      emit(v)
      println("End")
    }
  }

