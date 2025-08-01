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