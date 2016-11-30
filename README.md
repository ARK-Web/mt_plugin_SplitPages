# 本文の任意箇所でページを分割するMT6対応プラグイン「SplitPage v2.0」

## 概要
ページ（エントリー、またはウェブページ）を本文中の任意の箇所で複数ページに分割するプラグインのMT6対応版です。 過去に [MT4対応版](http://www.ark-web.jp/blog/archives/2009/03/splitpage.html) として開発したものをベースに、MT6対応版として復活させました。

* タグ: <code><$MTSplitPageLists$></code>  
* タグの属性: hide, splitpage_cut, split

## 動作条件

* MT6対応
* MTクラウド対応
* ダイナミックパブリッシングには対応していません。
* [DynamicMTML対応](https://alfasado.net/news/201412241355.html)

## ダウンロード

* <https://github.com/ARK-Web/mt_plugin_SplitPages>
* ライセンス: MIT License

## インストール方法

1. zipファイルを解凍してできる [SplitPage] ディレクトリを MTの pluginsディレクトリにアップロードします。

2. 「記事」、または「ウェブページ」テンプレートの <code><$mt:EntryBody$>、<$mt:PageBody$></code> タグに split="1" というモディファイアを指定します。

※EntryMoreやPageBodyには非対応です。

```html
例）  
  <mt:EntryBody split="1">  
  <mt:PageBody  split="1">  
```

## 使い方

### 分割指定

記事本文、またはウェブページの本文中でページ分割したい箇所に  
  
````
[[SplitPage]]  
````
  
と記述するだけです。

````
本文１  
[[SplitPage]]  
本文２  
[[SplitPage]]  
本文３  
````

とすれば、３ページに分割されてページが生成されます。

### 分割したコンテンツの前後に任意の文字列を埋め込む

split処理時に、コンテキスト変数「splitpage_header」「splitpage_footer」が存在していれば、分割したコンテンツの前後にその値が埋め込まれます。

「split」モディファイアが呼ばれるより前に、変数「splitpage_header」「splitpage_footer」をテンプレートなどでセットしてください。

**splitpage_header**
この変数値は、Split分割後のコンテンツ冒頭に出力されます。
なお、1ページ目には出力されません。

**splitpage_footer**
この変数値は、Split分割後のコンテンツ末尾に出力されます。
なお、1ページ目には出力されません。

**テンプレート記述例**  

````html
 <mt:SetVarBlock name="splitpage_header">  
  この行はSplitPageヘッダーです。EntryTitle=「<$mt:EntryTitle$>」  
  </mt:SetVarBlock>  
  <mt:SetVarBlock name="splitpage_footer">  この行はSplitPageフッターです。EntryID=「<$mt:EntryID$>」  
  </mt:SetVarBlock>  
  
  <$mt:EntryBody split="1"$>
````

このようにテンプレートを記述すると、

記事本文が以下の場合、

````
こんにちは
[[SplitPage]]
ここは2ページ目です
[[SplitPage]]
ここは3ページ目です
````

ファイルに出力される内容は以下の通りになります。

````
【1ページ目】  
　　　　こんにちは  
  
  
【2ページ目】  
　　　　この行はSplitPageヘッダーです。EntryTitle=「記事のタイトル」  
　　　　ここは2ページ目です  
　　　　この行はSplitPageフッターです。EntryID=「記事のID」  
  
【3ページ目】  
　　　　この行はSplitPageヘッダーです。EntryTitle=「記事のタイトル」  
　　　　ここは3ページ目です  
　　　　この行はSplitPageフッターです。EntryID=「記事のID」  
````


### ページングリンクの生成

ページングリンクはファンクションタグ <code><mt:SplitPageLists></code> で生成されます。  
MTSplitPageListsには二つのモディファイアが提供されています。  

**link_start**  
各ページングリンクの前につけるHTMLタグなどを指定します  
  
**link_end**  
各ページングリンクの後につけるHTMLタグなどを指定します。     
たとえば、  

````
<$mt:SplitPageLists link_start="<span class='page'>" link_end="</span>"$>
````

のように指定すると、仮に分割によって3ページある場合は、

````
<span class="page">1</span>      <!-- 自ページへのリンクはなし -->  
<span class="page_num_bg">  
  <a href="2ページ目へのURL">2</a>  
</span>  
<span class="page">  
  <a href="3ページ目へのURL">3</a>  
</span>  
````

となります。

なお、現在ページにはリンクがはられません（上の例は1ページ目のページングリンクの出力例です。そのため、1ページ目にはリンクがはられていません。）

### トップページやRSSなどに2ページ目以降が出ないようにする

分割した2ページ目以降の内容を、記事概要などで表に出したくない場合があります（indexページやRSSなど）。  
グローバルモディファイア「splitpage_cut」を指定すると、2ページ目以降を削除した本文を取り出せるようになります。  

**splitpage_cut="1 | 0"**  
="1"を指定すると、 ``[[SplitPage］`` 以降の本文がカットされます。

````
<mt:EntryBody splitpage_cut="1">
````

例えば「ブログ記事概要」テンプレートの mt:EntryBody に splitpage_cut="1" と書いておけば、2ページ目以降をカットした本文が出力されます。
