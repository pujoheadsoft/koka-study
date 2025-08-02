module learn/handler

import std/num/random

/**
 * エフェクト名と操作名が同じ、かつ操作が一つの場合、このように書ける
 * effect ctl raise( msg : string ) : a
 */
// raise というエフェクト型
effect raise
  // 型が (msg : string) -> raise a である raise という操作
  ctl raise(msg : string) : a

fun safe-divide(x : int, y : int) : raise int
  if y == 0 then
    raise("division by zero")
  else
    x / y

fun raise-const() : int
  with handler
    ctl raise(msg) 42
  8 + safe-divide(8, 0)

// 上記の構文糖
fun raise-const2() : int
  with ctl raise(msg) 42
  8 + safe-divide(8, 0)

pub fun test-raise-const()
  raise-const().println

// ------------------------------------
// resume (再開) の例

effect ask<a>
  ctl ask() : a

fun add-twice() : ask<int> int
  ask() + ask()

// 固定値を返す ask の例
fun ask-const() : int
  with ctl ask() resume(21)
  add-twice()

// ランダムな値を返す ask の例
fun ask-random() : random int
  with ctl ask() resume(random-int())
  add-twice()

pub fun test-ask-const()
  ask-const().println

pub fun test-ask-random()
  ask-random().println

// ハンドラのスコープに直接戻る例
// 一回目の ask の呼び出しは再開し、42を返す
// しかし
// 二回目の ask の呼び出しは再開せず、ask-onceのコンテキストに直接0を返す
// なので結果は 0 になる
fun ask-once() : int
  var count := 0
  with ctl ask()
    count := count + 1
    if count <= 1 then
      resume(42)
    else
      0
  add-twice()

pub fun test-ask-once()
  ask-once().println
// ------------------------------------
// 末尾再開操作


// 末尾に再開がある場合、このように書ける
// funとして宣言した方が一般的なctl操作より効率的らしい
fun ask-const2() : int
  with fun ask() 21
  add-twice()

// 上記を脱糖したもの
fun ask-const2-desugaring() : int
  with ctl ask() {
    val f = fn() { 21 }
    resume( f() )
  }
  add-twice()

// 任意の操作が末尾再開的でなければならないことを宣言することもできる
effect ask2<a>
  // ctl じゃなくて fun を使う
  fun ask2() : a

// -----------------------------

// ---------------------------------
// 値操作

effect val width : int

// width を通常の値であるかのように参照できる(内部的には操作を呼びだすが)
fun prettry-internal(line : string) : width string
  line.truncate(width)

fun pretty(d : string) : width string
  prettry-internal(d)

fun pretty-thin(d : string) : string
  with val width = 6
  pretty(d)

pub fun test-pretty-thin()
  pretty-thin("This is a long line that should be truncated.").println

// ---------------------------------
// ハンドラの抽象化

// エフェクト
effect fun emit(msg : string) : ()

// emitエフェクトを使うやつ
fun ehello() : emit ()
  emit("Hello, world!")
  emit("This is a second message.")

// emitエフェクトの汎用的なハンドラ
fun emit-console(action : () -> <console/console,emit|e> a) : <console/console|e> a
  with fun emit(msg) println(msg)
  action()

// 汎用的なハンドラを使わない版
fun ehello-console() : console ()
  with fun emit(msg) println(msg)
  ehello()

// 汎用的なハンドラを使う版
fun ehello-console2() : console ()
  with emit-console
  ehello()

// 上記を脱糖したもの
fun ehello-console2-desugaring() : console ()
  emit-console(fn() { 
    ehello() 
  })


fun emit-collect(action : () -> <emit|e> ()) : e string
  var lines := []
  with handler
    // return操作はハンドラの最終的な結果を変更する。これがないと()しか出力されない。
    return(x)     lines.reverse.join("\n")
    fun emit(msg) lines := Cons(msg, lines)
  action()

pub fun test-emit-collect()
  with emit-collect
  ehello().println

// `raise`が呼び出されたときにハンドリング関数を適用する、汎用的な `catch` ハンドラ
fun catch(hnd : (string) -> e a, action : () -> <raise|e> a) : e a
  with ctl raise(msg) hnd(msg)
  action()

pub fun example-catch()
  with catch(fn (msg) { println("error: " ++ msg); 42 })
  safe-divide(1, 0)

// 例外的なアクションを`maybe`型を返すものに変換する汎用ハンドラ
fun raise-maybe(action : () -> <raise|e> a) : e maybe<a>
  with handler
    return(x)      Just(x)
    ctl raise(msg) Nothing
  action()

pub fun example-div42()
  (raise-maybe { safe-divide(1, 0) }).default(52)