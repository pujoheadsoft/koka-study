module learn/basic

/*
 * VSCode から実行するには
 * pub をつける
 * main, examle..., test... などの命名である
 * 必要がある
 */
pub fun main() {
  println("Hello, World!")
}

// インデントされたブロックは自動的に中括弧で囲まれる
pub fun example-auto-curly-braces()
  println("Hello, World! 2")

// Kokaは匿名関数が関数呼び出しの後に続くことを許可している。
// これは末尾ラムダとして知られている。
pub fun example-print10()
  for(1, 10) fn(i)
    println(i)

// 上記を脱糖したもの
pub fun example-print10-desugaring()
  for(1, 10, fn(i) {
    println(i)
  })


/**
 * 引数のない匿名関数は fn を省略できる
 * repeatは引数のない関数をうけるのでそれで試してみる
 */
pub fun example-printhi10()
  repeat(10)
    println("hi")

// 上記を脱糖したもの
pub fun example-printhi10-desugaring()
  repeat(10, fn () { println("hi") })

// fn を省略できるのは while ループにとって特に便利
pub fun example-print11()
  var i := 10
  while { i >= 0 } // fn() を省略できる
    println(i)
    i := i - 1

// withで使うやつ
fun twice(f)
  f()
  f()

// 愚直に書いたやつ
pub fun test-twice()
  twice
    twice
      println("hi")

// 上記を脱糖したもの
pub fun test-twice-desugaring()
  twice(fn() {
    twice(fn() {
      println("hi")
    })
  })

// with 文は、それに続くすべての文を匿名関数ブロックに入れ、それを最後のパラメーターとして渡す。
pub fun test-with1()
  with twice
  with twice
  println("hi")


// with 文は、以下のように変数パラメーターをバインドすることができる
pub fun test-with2() {
  with x <- list(1, 10).foreach
  println(x)
}

// 上記を脱糖したもの
pub fun test-with2-desugaring()
  list(1, 10).foreach(fn(x) {
    println(x)
  })

// `finally`関数は、スコープを抜ける際に実行される関数を最初の引数として取る
pub fun test-finally()
  with finally { println("exiting...") }
  println("entering...")
  throw("oops") + 42

// 上記を脱糖したもの
pub fun test-finally-desugaring()
  finally(
    fn() {
      println("exiting...")
    },
    fn() {
      println("entering...")
      throw("oops") + 42
    }
  )

// with とハンドラ ----

effect fun emit(msg : string) : ()

fun hello() : emit ()
  emit("hello world")

// with は effectのハンドラと一緒に使うと便利
pub fun test-hello-console1() : console ()
  with handler
    fun emit(msg) println(msg)
  hello()

// 上記を脱糖したもの
pub fun test-hello-console1-desugaring() : console ()
  (handler {
    fun emit(msg) {
      println(msg)
    }
  }) fn () {
    hello()
  }

// 別の形で書いたもの
pub fun test-hello-console1-desugaring2() : console ()
  val h = handler {
    fun emit(msg) {
      println(msg)
    }
  }
  h fn () {
    hello()
  }

// 一つの操作しかないエフェクトについては、handlerキーワードを省略できる
pub fun test-hello-console2() : console ()
  with fun emit(msg) println(msg)
  hello()

