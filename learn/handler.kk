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

// handler {} と handle (action) は同じ意味
// handle(action) { ... } ≡ (handler { ... } )(action)
fun emit-console2(action)
  handle (action)
    emit(msg) println(msg)

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

/* 状態エフェクト */
effect state<a>
  fun get() : a
  fun set(x : a) : ()

fun sumdown(sum : int = 0) : <state<int>, div> int
  val i = get()
  if i <= 0 then
    sum
  else
    set(i - 1)
    sumdown(sum + i)

/* 一般的な状態ハンドラ */
fun state(init : a, action : () -> <state<a>, div|e> b) : <div|e> (b, a)
  var st := init
  with handler
    return(x) (x, st)
    fun get() st
    fun set(i) st := i
  action()

pub fun example-sumdown()
  state(10)
    sumdown()

/* 一般的な状態ハンドラ2 */
fun state2(init : a, action : () -> <state<a>, div|e> b) : <div|e> (b, a)
  var st := init
  // 単一の`return`操作のみを含むハンドラ
  // このハンドラはエフェクトを全くハンドリングせず、関数の最終的な結果を変換するだけ
  with return(x) (x, st)
  with handler
    fun get() st
    fun set(i) st := i
  action()

pub fun example-sumdown2()
  state2(10)
    sumdown()

// ---------------------------------

// ---------------------------------
// ハンドラの組み合わせ

fun no-odds() : <raise, state<int>> int
  val i = get()
  if i.is-odd then raise("no odds")
  else
    set(i / 2)
    i

// stateハンドラとraiseハンドラを組み合わせる
fun state-raise(init) : div (maybe<int>, int)
  with state(init)
  with raise-maybe
  no-odds()

// 別の順序で組み合わせる
fun raise-state(init) : div maybe<(int, int)>
  with raise-maybe
  with state(init)
  no-odds()

pub fun example-state-raise()
  state-raise(10) // (Just(10),5)

pub fun example-state-raise2()
  state-raise(9) // (Nothing,9)

pub fun example-state-raise3()
  state-raise(0) // (Just(0),0)

pub fun example-raise-state()
  raise-state(10) // Just((10,5))

pub fun example-raise-state2()
  raise-state(9) // Nothing

pub fun example-raise-state3()
  raise-state(0) // Just((0,0))

// ---------------------------------

// ---------------------------------
// エフェクトのマスキング


fun mask-emit()
  // emit操作に対するネストされたハンドラ
  with fun emit(msg) println("outer: " ++ msg)
  with fun emit(msg) println("inner: " ++ msg)
  emit("hi")
  mask<emit>
    emit("there")

/*
  上記を実行すると次のように表示される
  inner: hi
  outer: there
*/
pub fun test-mask-emit()
  mask-emit()

// ---------------------------------

// ---------------------------------
// 複数回の再開

effect ctl choice() : bool

fun xor() : choice bool
  val p = choice()
  val q = choice()
  if p then !q else q

fun choice-rundom(action : () -> <choice, random|e> a) : <random|e> a
  with fun choice() random-bool()
  action() // ランダムにTrue, Falseを返す

pub fun example-choice-random()
  choice-rundom(xor)

fun choice-all(action : () -> <choice|e> a) : e list<a>
  with handler
    return(x) [x]
    ctl choice() resume(False) ++ resume(True)
  action()

pub fun example-choice-all()
  choice-all(xor) // [False,True,True,False]