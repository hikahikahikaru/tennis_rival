# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 📁 フォルダの役割とファイル配置のルール

Tennis Rivalアプリでは、コードを綺麗で読みやすく保つために「見た目」「ルール」「考える処理」を別々のフォルダに分けて管理します。新しいファイルを作る時は、以下の表を参考にしてください。

| フォルダ名 | 役割（何を入れるか） | 具体例 |
| :--- | :--- | :--- |
| **`widgets/`** | **画面の小さなパーツ（見た目）** | ボタン、試合結果カード、ナビゲーションバーなど |
| **`constants/`** | **デザインと文字のルールブック** | 色（メインカラー等）、アイコンのサイズ、固定のテキスト（「ホーム」など） |
| **`models/`** | **データの形と「考える処理」** | ナビゲーションのデータ型、アイコンの色やサイズを決定する判定ロジック |
| **`screens/`** | **画面全体（土台）** | ホーム画面、試合登録画面、確認画面など |

## 💡 コーディングの3ヶ条（美しいコードを書くための約束）

**1. Widgetには「描画処理」だけを書く**
`widgets/` や `screens/` のファイルは、極限までシンプルに保ちます。「ただデータを受け取って、画面に並べるだけ」の存在にするのが理想です。

**2. 色・サイズ・文字の「ベタ打ち」はしない**
「サイズを42にする」「色を緑（0xFF13643B）にする」といった具体的な数字や文字は、Widgetに直接書きません。後から一括でデザインを変更できるよう、必ず `constants/` フォルダ内のファイル（`app_colors.dart`や`app_sizes.dart`など）に定義してから呼び出します。

**3. 「もし〇〇なら」の判定ロジックはModelに任せる**
「もし『登録ボタン』ならサイズを大きくして緑色にする」といった条件分岐（ロジック）はWidget内に書かないようにします。代わりに `models/` 内のデータクラスに計算用の機能（メソッド）を持たせます。Widget側は「計算済みの結果をちょうだい」とお願いするだけの状態にしてください。
