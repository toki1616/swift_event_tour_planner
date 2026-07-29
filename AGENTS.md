# Event Tour Planner Development Guide

## Communication

- ユーザーへの説明、コミットメッセージ、PRタイトルは原則として日本語を使用する。
- 実装前に既存コードとGitの状態を確認し、関係のない変更を作業へ含めない。
- 要件が既存の設計で実現できる場合は、その設計を優先して再利用する。

## Project

- SwiftUIで構築したiOSアプリで、iOS 17.0以上を対象とする。
- 永続化にはSwiftData、支出の可視化にはSwift Chartsを使用する。
- 外部ライブラリを追加する前に、Apple標準フレームワークで実現できないか確認する。
- 外部依存を追加する必要がある場合は、実装前にユーザーへ確認する。

## Architecture

- MVVMにRepositoryパターンを組み合わせ、Feature単位でコードを整理する。
- Viewは表示とユーザー操作を担当し、保存処理やビジネスロジックを直接持たせない。
- ViewModelは入力検証、画面状態、Repositoryの呼び出しを担当する。
- SwiftDataへのデータアクセスはRepositoryを経由する。
- 新規登録と編集で同じ項目を扱う場合は、共通のViewとDraftを利用する。
- 親画面で保存するまで永続データを変更したくない入力にはDraftを利用する。

## Directory Structure

- `EventTourPlanner/Features/Events`: イベントの一覧、詳細、編集、ViewModel
- `EventTourPlanner/Features/Expenses`: 費用の編集
- `EventTourPlanner/Features/Tours`: ツアーの一覧、詳細、編集、予定編集、ViewModel
- `EventTourPlanner/Models`: SwiftDataモデルとDraft
- `EventTourPlanner/Repositories`: RepositoryのProtocolとSwiftData実装
- `EventTourPlanner/Extensions`: 複数画面で再利用するView拡張
- `EventTourPlannerTests`: Model、ViewModel、Repositoryのテスト
- `EventTourPlannerUITests`: 主要なユーザーフローのUIテスト

## UI and Localization

- 日時、通貨、標準メニューは端末の言語・地域設定に従って表示する。
- アプリ固有の表示文言は`EventTourPlanner/Localizable.xcstrings`で管理する。
- 入力画面には共通のキーボード終了処理を適用する。
- 詳細画面は閲覧専用とし、編集ボタンから編集画面へ移動する。
- UIテストで操作する要素には、安定したAccessibility Identifierを設定する。
- 既存のAccessibility Identifierは、対応するUIテストも同時に修正できる場合だけ変更する。

## Data Relationships

- `TourPlan`は複数の`LiveEvent`と`TourScheduleItem`を持つ。
- `LiveEvent`は複数の`EventExpense`を持つ。
- イベント削除時は、紐づく費用をcascadeで削除する。
- ツアー削除時は、移動・宿泊予定をcascadeで削除し、イベントとの関連は解除する。
- SwiftDataのRelationshipや削除規則を変更する場合は、既存データへの影響を確認する。

## Error Handling

- エラーダイアログ表示時に、入力画面を自動で閉じない。
- ダイアログのOK操作ではダイアログだけを閉じ、入力内容を保持する。
- 保存に失敗した場合は、永続データを中途半端な状態にしない。

## Tests

- Model、ViewModel、Repositoryの振る舞いを変更した場合は、対応するテストを追加または修正する。
- 主要なユーザー操作を変更した場合は、必要に応じてUIテストを追加または修正する。
- UIテストは`--uitesting`を使用し、インメモリのSwiftDataで実行する。
- 変更後は関連テストを実行し、PR前またはリリース前には全テストを実行する。
- Xcodeでは`⌘ + U`で全テストを実行できる。
- CLIで実行する場合は、利用可能なシミュレータを確認してから次の形式を使用する。

```sh
xcodebuild test \
  -project EventTourPlanner.xcodeproj \
  -scheme EventTourPlanner \
  -destination 'platform=iOS Simulator,name=<available simulator>'
```

## Git Workflow

- 機能開発は`feature/機能名`ブランチで行う。
- リリース準備は`release/バージョン`ブランチで行う。
- `main`へ直接コミットしない。
- 機能や修正の単位でコミットを分ける。
- 関係のないファイルや、作業開始前から存在する未コミット変更をステージしない。
- ユーザーの変更を許可なく破棄、上書き、stashしない。
- コミット前に`git diff --check`とステージ対象を確認する。
- リリースタグは、mainへのマージ完了後のコミットへ付与する。

## Release Versioning

- Versionは`Major.Minor.Patch`形式を使用する。
- Buildは正の整数を使用し、同じVersionで再配布するたびに増やす。
- 例: Version `1.0.0`、Build `1`。次のビルドはBuild `2`。
