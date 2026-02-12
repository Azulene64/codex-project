# iPhone Trackpad for Mac - MVP Plan

## 0. Plan mode 方針（手戻り最小化）
- **先に仕様を凍結**: 入力閾値・イベント定義・順序制御・SLOをコード化可能な形で先に固定する。
- **依存順で実装**: `T3(通信基盤)` → `T2(Mac注入)` → `T1(iOS状態機械)` → `T4/T5(ペアリング/権限)` → `T6(設定)` → `T7(計測)`。
- **E2Eを早期成立**: クリック/移動の最小経路を先に通し、以降の機能追加で退行しないよう検証を積む。
- **受入基準をテスト可能化**: KPIを計測項目・試験手順・合否条件に分解し、リリース可否判定を自動化する。

---

## 1. 目的・非目的
### 目的
iPhoneを机上トラックパッドとして使い、Macのポインタ操作（移動/クリック/ドラッグ/スクロール/ズーム代替）を低遅延で実現する。

### 非目的
- キーボード入力
- 3本指/4本指ジェスチャ
- クラウド経由遠隔操作
- ファイル転送

---

## 2. 対象環境（MVP）
- iPhone: 12以降
- iOS: 18以降（CIで最小対応バージョン固定）
- Mac: Apple Silicon優先、macOS Monterey以降
- ネットワーク: 同一LAN、IPv4優先（IPv6はベストエフォート）

---

## 3. システム構成
## 3.1 コンポーネント
1. **iOSアプリ**
   - タッチ入力収集
   - ジェスチャ状態機械
   - 接続/再接続制御
   - 設定UI・永続化
2. **macOS常駐エージェント**
   - WebSocketサーバ
   - 入力注入（CGEvent）
   - Accessibility権限チェック
   - メニューバーUI・許可端末管理
3. **通信層**
   - WebSocket（`ws`/`wss`）
   - heartbeat / seq順序制御 / 再接続

## 3.2 主要データフロー
1. iOSがジェスチャ判定し、イベントをJSON化。
2. `seq`単調増加で送信。
3. Mac側で`session_id + seq + ts_ms`整合チェック。
4. 妥当イベントのみCGEventへ変換して注入。
5. ping/pongで疎通監視し、切断時は指数バックオフ再接続。

---

## 4. UI仕様（横固定・最小UI）
- 全面入力面
- 左上: 設定
- 右上: 接続状態 + 感度プリセット
- 触覚フィードバック差分
  - 左クリック
  - 右クリック
  - ドラッグ開始
- 切断時: 右上状態即時反映 + 軽通知

---

## 5. 入力・ジェスチャ仕様（固定値）
## 5.1 判定閾値
- タップ最大時間: `180ms`
- タップ最大移動: `10px`
- ダブルタップ間隔: `250ms`（設定: `200/250/300ms`）
- ダブルタップ位置許容: `20px`
- 2本指同時接地許容: `80ms`
- 長押し: `2000ms`
- 長押し待機中キャンセル移動量: `15px`
- 2本指判定ウィンドウ: `60ms`
- 2本指ロック: 判定後の切替不可

## 5.2 動作定義
- 1本指移動 → カーソル相対移動
- 1本指シングルタップ → 左クリック
- 1本指ダブルタップ → 左ダブルクリック
- 2本指タップ → 右クリック
- 1本指2秒長押し → ドラッグモード（押下維持→移動→離してドロップ）
- 2本指同方向移動 → 縦スクロール（横スクロールは設定ON時のみ）
- 2本指逆方向移動 → ズーム代替（`⌘ + scroll`）

## 5.3 ピンチ→ズーム換算
- `steps = round(k * ln(scale))`
- 既定値: `k = 12`
- 1送信クランプ: `[-4, +4]`
- デッドゾーン: `|ln(scale)| < 0.02` は送信しない
- 送信周期上限: `60Hz`

---

## 6. 通信プロトコル（最小）
## 6.1 共通JSONスキーマ
```json
{
  "type": "move|click|drag_start|drag_move|drag_end|scroll|zoom|ping|pong|error",
  "ts_ms": 1730000000000,
  "seq": 1234,
  "device_id": "hashed-device-id",
  "session_id": "uuid-v4"
}
```

## 6.2 イベント別ペイロード
- `move`: `{ "dx": float, "dy": float }`
- `click`: `{ "button": "left|right", "count": 1|2 }`
- `drag_start`: `{ "button": "left" }`
- `drag_move`: `{ "dx": float, "dy": float }`
- `drag_end`: `{}`
- `scroll`: `{ "sx": float, "sy": float, "phase": "changed|ended" }`
- `zoom`: `{ "steps": int }`
- `error`: `{ "code": "...", "message": "..." }`

## 6.3 制御ルール
- `seq` はセッション内で単調増加
- 欠落検知時: 補間せず、**最新優先で破棄**
- 再接続: `0.5s → 1s → 2s → 4s → max 5s`
- 切断検知: ping/pongで3秒以内

---

## 7. セキュリティ・権限
- 初回ペアリング: 6桁コード（60秒有効、3回失敗で無効）
- 許可端末リスト: Mac側で個別失効可能
- 盗聴対策: 可能なら `wss` + TLS1.3
- リプレイ対策: `session_id + seq + ts_ms`整合検証
- Accessibility未許可時:
  - 入力注入停止
  - システム設定への誘導UI表示

---

## 8. 非機能要件（SLO）
- 片道入力遅延: `p50 <= 25ms`, `p95 <= 50ms`
- 切断検知: `<= 3秒`
- CPU目標: iPhone平均 `< 15%`、Mac平均 `< 10%`
- バッテリー目安: 30分で iPhone消費 `< 8%`
- クラッシュフリー: `>= 99.5% / 7日`

---

## 9. テレメトリ・データ倫理
- 生タッチ座標は保存しない
- 保存項目: 遅延、切断回数、誤認識率、OS/機種、アプリバージョン
- 匿名化: 端末IDをハッシュ化、IP非保存
- 保持期間: 30日（デバッグ詳細）→ 以降は集約値のみ
- 同意: 初回起動時に明示、設定でオプトアウト可

---

## 10. 受入基準（MVP）
## 10.1 機能成立率（8項目、各95%以上）
1. カーソル移動
2. 左クリック
3. 左ダブルクリック
4. 右クリック
5. ドラッグ＆ドロップ
6. 縦スクロール
7. ズーム代替（`⌘+scroll`）
8. 切断後自動再接続

## 10.2 品質基準
- 右クリック誤発火 `< 2%`
- ドラッグ誤発火 `< 1%`
- Finder / Safari / Preview で操作成立
- 30分連続テストで切断復帰成功率 `>= 99%`

---

## 11. 実装計画（依存順）
## フェーズA: 基盤固定（Week 1）
### A1. 契約先行
- プロトコルJSON schema確定
- イベント型とバージョニング方針決定（`protocol_version`追加）
- Done条件: iOS/Macで同一schemaの自動検証が通る

### A2. 計測足場
- `ts_ms`基準時刻の整合手順（送信/受信/注入）
- レイテンシ測定ロガー（匿名）
- Done条件: p50/p95がダッシュボードで可視化

## フェーズB: E2E最小ループ（Week 2）
### B1. T3 WebSocketセッション層
- 心拍・再接続・seq検証
- Done条件: LAN切断/復帰シナリオが自動試験で安定

### B2. T2 Mac入力注入層
- move/click/scroll/modifier注入
- Accessibility権限未付与時のブロック
- Done条件: ローカルテストで入力注入成功

### B3. T1 iOS入力状態機械（最小）
- 1本指移動/タップ/ダブルタップ
- Done条件: E2Eで移動+左クリック+ダブルクリック成立

## フェーズC: ジェスチャ拡張（Week 3）
### C1. 右クリック・ドラッグ
- 2本指タップ
- 長押し2秒→drag開始/終了
- Done条件: 誤発火率の閾値内

### C2. スクロール・ズーム代替
- 2本指同方向/逆方向判定
- `k*ln(scale)`実装・60Hz制限
- Done条件: Finder/Safari/Previewで操作成立

## フェーズD: セキュリティ・運用（Week 4）
### D1. T4 ペアリング/端末管理
- 6桁コード・失敗回数制限・失効UI

### D2. T5 権限ガイドUI
- macOS設定誘導
- 未許可時状態表示

### D3. T6 設定画面
- 感度プリセット
- ダブルタップ間隔
- 横スクロールON/OFF

### D4. T7 テレメトリ最小実装
- 収集同意・オプトアウト
- 30日保持ポリシー反映

## フェーズE: リリース判定（Week 5）
- 受入試験一式
- 性能/安定性試験
- 既知制約の明文化

---

## 12. タスク分解（次工程）
- **T1**: iOS入力状態機械
- **T2**: Mac入力注入層
- **T3**: WebSocketセッション層
- **T4**: ペアリング/端末管理
- **T5**: 権限ガイドUI
- **T6**: 設定画面とプリセット
- **T7**: テレメトリ最小実装と評価レポート

### 実行順（推奨）
`T3 -> T2 -> T1 -> T4 -> T5 -> T6 -> T7`

---

## 13. リスクと対策
- **ネットワーク揺らぎで遅延増**
  - 対策: 送信レート制御（60Hz上限）、最新優先破棄、再接続指数バックオフ
- **Accessibility未許可で「動かない」誤解**
  - 対策: 初回起動時のガイド、常時ステータス表示、操作不能理由を明示
- **ジェスチャ誤認識（右クリック/ドラッグ）**
  - 対策: 閾値固定 + 端末別の感度プリセット + 誤認識率の継続計測
- **wss導入コスト**
  - 対策: MVPは`ws`許容、次版でTLS証明書運用を標準化

---

## 14. 初期マイルストーン定義
- **M1 (Week 2末)**: move/click/double-click E2E
- **M2 (Week 3末)**: right-click/drag/scroll/zoom E2E
- **M3 (Week 4末)**: pairing/permissions/settings/telemetry
- **M4 (Week 5末)**: 受入基準達成、MVP Go/No-Go判定

---

## 15. 参考文献（APA）
- Apple. (n.d.). *CGEventCreateMouseEvent*. Apple Developer Documentation.
- Apple. (n.d.). *CGEventTapCreate*. Apple Developer Documentation.
- Apple. (2023, October 12). *If an app would like to connect to devices on your local network*. Apple Support.
- Apple. (n.d.). *Allow accessibility apps to access your Mac*. Apple Support.
- Fette, I., & Melnikov, A. (2011). *The WebSocket Protocol* (RFC 6455). IETF.
- Rescorla, E. (2018). *The Transport Layer Security (TLS) Protocol Version 1.3* (RFC 8446). IETF.
