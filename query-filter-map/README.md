# Query Filter (Map 射影) テスト

DynamoDB Local を使って、Query の `FilterExpression` で Map 属性のネストしたフィールドを
`=` で比較するフィルタリングが期待通り動くかを確認するためのテスト一式。

`ExpressionAttributeNames` のプレースホルダーを使わないパターンを基本とし、
DynamoDB の予約語を扱う場合に必要になるプレースホルダーのパターンも一部残している。

## 構成

- `common.sh` - エンドポイント・テーブル名・GSI名などの共通設定
- `data.json` - テストデータ（50件、6グループ、グループごとに異なる Map 構造・ネスト階層）
- `setup.sh` - テーブル作成（GSI 含む）+ `data.json` の投入
- `query-filter.sh` - Map 射影に対する `=` フィルタの実行例（テーブル Query / GSI Query）
- `cleanup.sh` - テーブル削除

## テーブル定義

- テーブル名: `QueryFilterMapTest`
- パーティションキー: `pk` (S) ... グループ (`GROUP#customer` / `GROUP#order` / `GROUP#device` / `GROUP#account` / `GROUP#shipment` / `GROUP#activity`)
- ソートキー: `sk` (S) ... `ITEM#001` など
- GSI: `AreaIndex` ... パーティションキー `area` (S) / ソートキー `pk` (S)
  - 全アイテムに付与したトップレベル属性 `area` (`JP`/`US`) で、グループを横断した Query を行うためのインデックス

## データ

Map のネスト階層（射影パス上の識別子の数）を変えたパターンを含む。

| グループ | 件数 | Map 属性 | ネスト階層 | フィールド |
| --- | --- | --- | --- | --- |
| `GROUP#customer` | 10 | `profile` | 2層 (`profile.tier`) | `tier` (premium/standard), `country` (JP/US) |
| `GROUP#order` | 10 | `details` | 2層 (`details.phase`) | `phase` (shipped/pending/cancelled), `priority` (high/low) |
| `GROUP#device` | 10 | `spec` | 2層 (`spec.os`) | `os` (ios/android), `model` |
| `GROUP#account` | 5 | `billing` | 3層 (`billing.subscription.tier`) | `tier` (gold/silver), `period` (monthly/yearly) |
| `GROUP#shipment` | 5 | `cargo` | 4層 (`cargo.box.dimension.X`) | `measure` (String: cm/inch), `amount` (Number), `detail` (Map: `{grade, weight}`) |
| `GROUP#activity` | 10 | `activity` | 2層 (`activity.status` / `activity.region`) | `status` (active/expired), `region` (JP/US) — いずれも予約語のためプレースホルダー参照用 |

上記 5 グループ（`customer`〜`shipment`）は DynamoDB の予約語を避けたフィールド名にしており、
`ExpressionAttributeNames` なしでフィルタできる。`activity` グループのみ、意図的に
予約語（`status` / `region`）をフィールド名に使い、プレースホルダーが必要になる例として残している。

各アイテムにはグループを横断した GSI 用の `area` (JP/US) 属性も付与している。

`GROUP#shipment` の `cargo.box.dimension` (3層目) は String (`measure`) / Number (`amount`) /
Map (`detail`) の3種類の型のフィールドを持ち、それぞれの型での `=` フィルタを確認できる。

## セットアップ

リポジトリルートで DynamoDB Local を起動する。

```sh
docker compose up -d
```

テーブル作成とデータ投入。

```sh
cd query-filter-map
./setup.sh
```

## フィルタのテスト

```sh
./query-filter.sh
```

### 基本パターン（プレースホルダーなし）

テーブル本体への Query（`pk` で絞り込み）:

- `profile.tier = "premium"` (2層)
- `details.phase = "shipped"` (2層)
- `spec.os = "ios"` (2層)
- `billing.subscription.tier = "gold"` (3層)
- `cargo.box.dimension.measure = "cm"` (4層 / String)
- `cargo.box.dimension.amount = 30` (4層 / Number)
- `cargo.box.dimension.detail = {grade: "A", weight: 5}` (4層 / Map の完全一致比較)
- `cargo.box.dimension.detail.grade = "A"` (5層 / Map 配下の単一フィールドのみを比較)

GSI (`AreaIndex`) への Query（`area` で絞り込み、グループを横断した結果を Map 射影でさらにフィルタ）:

- `area = "JP"` かつ `profile.tier = "premium"`

GSI Query は `area = "JP"` の時点で複数グループのアイテムを返すが、対象の Map 属性を
持たないアイテムは `FilterExpression` の評価対象外として自動的に除外される。

### 参考パターン（プレースホルダーあり）

`GROUP#activity` の `status` / `region` は DynamoDB の予約語のため、式の中では
`ExpressionAttributeNames` でプレースホルダー（`#st` / `#rg`）に置き換える必要がある。

- `activity.status = "active"` （`#st` で置換）
- `activity.region = "JP"` （`#rg` で置換）
- GSI (`AreaIndex`): `area = "JP"` かつ `activity.status = "active"`

## クリーンアップ

```sh
./cleanup.sh
```

## 補足

`docker-compose.yml` の `dynamodb-local` サービスは、`dynamodb-data` ボリュームに
書き込めるよう `user: root` を指定している（デフォルトの非 root ユーザーだと
ボリュームの所有権の関係で DB ファイルを開けず、リクエストが応答なしでハングする）。
