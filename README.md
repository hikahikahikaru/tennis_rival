# Tennis Rival 開発環境セットアップガイド

開発チームへようこそ！このアプリは、表側の画面を「Flutter」、裏側のデータベースを「Supabase」という技術で作っています。
お使いのPC（Mac / Windows）に合わせて、順番に環境を構築していきましょう。

---

## 💡 なぜこれらのツールを入れるの？（基礎知識）

作業を始める前に、これから入れるツールの役割を簡単に説明します。

* **VS Code (Visual Studio Code)**
  コードを書くための高機能な専用ノートです。今回はこれを使ってすべての作業を行います。
* **Docker Desktop**
  PCの中に「アプリ専用の安全な隔離部屋」を作るツールです。裏側のデータベース（Supabase）は複雑なシステムなので、あなたのPCを汚さずにそのまま動かすために絶対必要になります。
* **WSL (Windowsのみ)**
  Windowsの中でDockerを動かすための「Linuxの土台」です。Macには最初から似た仕組みがあるため不要です。
* **Flutter SDK**
  スマホアプリを作るための「道具箱」です。これをPCに直接入れることで、スマホの画面をPC上に表示できるようになります。

---

## 🍎 Mac用 セットアップ手順

Macを使っている方向けの手順です。順番通りに進めてください。

### 1. VS Codeのインストール
1. [VS Code公式サイト](https://code.visualstudio.com/)にアクセスし、「Download Mac Universal」をクリックします。
2. ダウンロードしたZipファイルをダブルクリックして解凍します。
3. 出てきた青いリボンのアイコン（Visual Studio Code）を、Macの「アプリケーション」フォルダにドラッグ＆ドロップして移動させます。

### 2. Docker Desktopのインストール
1. [Docker公式サイト](https://www.docker.com/products/docker-desktop/)にアクセスし、「Download for Mac」をクリックします。（※お使いのMacがM1/M2チップなら「Apple Silicon」、Intel製なら「Intel chip」を選んでください）
2. ダウンロードした `.dmg` ファイルを開き、Dockerのアイコンを「Applications」フォルダにドラッグします。
3. アプリケーションから「Docker」を起動します。
4. 規約画面が出たら「Accept」を押し、設定画面では **「Use recommended settings（推奨設定を使用）」** にチェックを入れて「Finish」を押します。
5. Macのパスワードを聞かれたら入力します。画面左下に緑色で「Engine running」と出れば準備完了です。このアプリは裏で開いたままにしておきます。

### 3. Flutter SDKのインストール
1. [Flutter公式サイト](https://docs.flutter.dev/get-started/install/macos)から、Mac用の最新SDK（Zipファイル）をダウンロードします。
2. ダウンロードしたファイルを解凍し、出てきた `flutter` フォルダを、ご自身の「ホームフォルダ（家のマークのフォルダ）」の中に移動させます。

### 4. プロジェクトのダウンロードと起動
1. VS Codeを開きます。
2. 画面上部のメニューバーから「ターミナル」＞「新しいターミナル」をクリックします。画面下部に黒い入力欄が出ます。
3. 以下のコマンドを1行ずつコピーして貼り付け、Enterを押します。
   ```bash
   # 1. コードをダウンロード
   git clone [https://github.com/hikahikahikaru/tennis_rival.git](https://github.com/hikahikahikaru/tennis_rival.git)
   
   # 2. ダウンロードしたフォルダに移動
   cd tennis_rival
   
   # 3. データベース（Supabase）を起動
   supabase start
   
   # 4. アプリ（Flutter）のフォルダへ移動
   cd mobile
   
   # 5. アプリを起動
   flutter run

---

## 💡 毎回の開発の進め方（重要）

環境構築が終わった後の、日々の作業の進め方です。
VS Codeの開き方と、ターミナル（黒い画面）の使い分けがポイントになります。

### 1. VS Codeの正しい開き方
1. VS Codeを起動します。
2. メニューの「ファイル」＞「フォルダーを開く」から、一番大元の `tennis_rival` フォルダ（Windowsなら `C:\github\tennis_rival` など）を開きます。
3. 画面左側のファイル一覧に、`mobile` フォルダと `supabase` フォルダの両方が見えている状態が正解です。

### 2. ターミナルを2つ立ち上げる（役割分担）
VS Codeの画面下部にあるターミナルパネルで、右上の「＋」ボタンや下向き矢印を使い、役割の違うターミナルを同時に2つ開いて切り替えながら使います。

#### 【ターミナル1：データベース用（Supabase）】
裏側のデータを動かすためのターミナルです。

* **[Macの場合]**
  * 種類: デフォルトのターミナル（zsh等）
  * やること: `supabase start` を実行
* **[Windowsの場合]**
  * 種類: `Ubuntu (WSL)`（「＋」ボタン横の矢印から選択）
  * やること: `cd /mnt/c/github/tennis_rival` を実行してから、`supabase start` を実行

#### 【ターミナル2：アプリ用（Flutter）】
スマホの画面を表示・更新するためのターミナルです。

* **[Mac/Windows 共通]**
  * 種類: デフォルトのターミナル（Macならzsh、WindowsならPowerShell）
  * やること: `cd mobile` を実行してアプリフォルダに入り、`flutter run` を実行

---
※作業を終了する時は、ターミナルで `Ctrl + C` を押すとそれぞれ停止できます。（データベースは `supabase stop` でも停止可能です）