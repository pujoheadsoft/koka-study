module learn/effect

import std/num/random

// エフェクトが存在しない場合 total と書く。totalは全域関数。totalは省略できる
fun square1(x : int) : total int { x * x }

// console はエフェクト
fun square2(x : int) : console int { println("execute"); x * x }

// div は発散（終わらない可能性がある）
fun square3(x : int) : div int { x * square3(x) }

// exn は例外が発生する可能性がある場合
fun square4(x : int) : exn int { throw("oops"); x * x }


fun combine-effects()
  val i = srandom-int() // 非決定的
  throw("oops")         // 例外
  combine-effects()     // 発散