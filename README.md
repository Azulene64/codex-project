# codex-project

iPhoneをMacのトラックパッドとして利用するMVP向けのSwift実装です。

## 含まれるもの

- `briefs/iphone-trackpad-mvp-plan.md`: 要件から整理したMVP計画。
- `sources/ios/TrackpadCore`: 共有ロジック（ジェスチャ状態機械、プロトコルモデル、再接続ポリシー、ズーム換算）。
- `sources/ios/iPhoneTrackpadApp`: iPhone向けSwiftUIアプリの骨格（入力面UI + WebSocket送信クライアント）。

## ローカルでの確認

```bash
cd sources/ios/TrackpadCore
swift test
```

## iPhoneアプリとして動かす手順

1. Xcode 16+ で iOS App プロジェクト（iOS 18）を作成
2. `sources/ios/iPhoneTrackpadApp/*.swift` をプロジェクトへ追加
3. Swift Package Dependencyとして `sources/ios/TrackpadCore` をローカル追加
4. 実機（iPhone 12以降）でビルド

## GitHubリポジトリ作成（手動）

この環境ではGitHub認証情報が無い場合があるため、必要に応じて以下で作成してください。

```bash
gh repo create <your-org-or-user>/<repo-name> --private --source . --push
```
