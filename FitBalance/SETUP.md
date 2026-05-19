# FitBalance - セットアップ手順

## 必要な環境
- macOS 14以降
- Xcode 15以降
- iOS 17以降のデバイス or シミュレータ

## Xcodeプロジェクト作成

1. Xcodeを起動 → 「Create New Project」
2. **iOS → App** を選択
3. 設定：
   - Product Name: `FitBalance`
   - Team: （自分のApple IDを選択）
   - Bundle Identifier: `com.yourname.FitBalance`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** にチェック ← 重要

4. 保存先を選んでプロジェクト作成

## ファイルの配置

Xcodeプロジェクトが作成されたら、このリポジトリの `FitBalance/` フォルダ内のファイルを以下の手順でXcodeに追加します。

1. **`FitBalanceApp.swift`** → デフォルトの `FitBalanceApp.swift` と置き換え
2. **`ContentView.swift`** → デフォルトの `ContentView.swift` と置き換え

3. Xcodeのプロジェクトナビゲータで `FitBalance` グループを右クリック
   → **「Add Files to FitBalance」**
   → 以下のフォルダを選択（フォルダ自体を追加、「Copy items if needed」にチェック）：
   - `Models/`
   - `ViewModels/`
   - `Views/`（ContentView.swift以外）
   - `Helpers/`
   - `Data/`

## ビルドと実行

1. シミュレータ（iPhone 15 Pro推奨）またはiPhone実機を選択
2. `Cmd + R` でビルド・実行

## 機能概要

| タブ | 機能 |
|------|------|
| ボディマップ | 全身の筋肉を偏差値で色分け表示。部位タップで詳細、選択してプラン作成 |
| 記録 | 種目・セット・重量を入力してトレーニングを記録 |
| プラン | AI生成のトレーニングプランを表示。部位ごとにカスタマイズ可能 |
| 履歴 | 過去のトレーニング記録を一覧表示 |

## 偏差値の見方

- **青（偏差値40未満）**: もっと鍛えるべき部位
- **緑（40〜60）**: バランスが取れている
- **赤（60超）**: 十分に鍛えられた部位

過去30日間のトレーニングボリューム（重量 × レップ × セット）を元に計算されます。
