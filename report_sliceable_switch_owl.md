#情報ネットワーク学演習II 12/13 レポート課題
===========
チーム名　owl  
メンバー 秋下 耀介、坂田 航樹、坂本 昂輝、佐竹 幸大、田中 達也、Jens Oetjen、齊藤 卓哉  

## 役割分担
* スライスの分割・統合プログラム、REST APIの作成　坂田
* 可視化のプログラム作成　秋下、坂本
* 経路選択アルゴリズム部分のレポート作成　坂田
* 可視化部分のレポート作成　秋下、坂本

## 課題 (スライス機能の拡張)
* スライスの分割・結合
	* スライスの分割と結合機能を追加する
* スライスの可視化
	* ブラウザでスライスの状態を表示
* REST APIの追加
	* 分割・統合のできるAPIを追加


## 解答
本課題に取り組むにあたり、実装箇所を以下の２つに切り分けた。
* スライスの分割・統合プログラム、REST API
* 可視化プログラム

以降、それぞれについて説明する。

### スライスの分割・結合

####　実行結果



### 可視化プログラム
本機能の実装を前回と同様に以下の２つに切り分けた。

* スライス情報の取得およびテキストファイル出力(担当：秋下)
* テキスト情報に基づいたvis.jsによるスライスの表示（担当：坂本）  
それぞれについての説明を以下に示す。

#### <a id="txt_format" style="color: black;">スライス情報のテキストファイル出力</a>
前回までの課題において、ノード（ホストおよびスイッチ）とリンクの情報をテキストファイル（toplogy.txt）に出力する他に、経路情報のファイル(path.txt)を出力するようプログラム（vis.rb）を拡張した。
今回はホストの情報の出力時に追加でスライスの情報を付加したい。そこで、
まず以下のファイルを変更し、スライス情報を保存するようにした。
* [lib/routing_switch.rb]()
* [vendor/topology/lib/view/topology_controller.rb]()
* [vendor/topology/lib/view/controller.rb]()
* [bin/slice]()


また、スライス情報を出力するにあたって、以下のファイルに変更を加えた。
* [vendor/topology/lib/view/vis.rb]()

以上のファイルの主な変更点について説明を行う。

##### lib/routing_switch.rb
ここでは、`topology_controller`の`update_slice`メソッドを、Sliceを引数として呼び出しているだけである。
```ruby
def update_slice
    @topology.update_slice(Slice.all)
end
```

##### vendor/topology/lib/view/topology_controller.rb
こちらでは、`routing_switch.rb`のように、`topology`の`update_slice`メソッドをsliceを引数として呼び出している。
```ruby
def update_slice(slice)
    @topology.update_slice(slice)
end
```


##### vendor/topology/lib/view/topology.rb
ここではまず、switchの扱いと同様に@slicesというインスタンス変数を用意した。
```ruby
def initialize
    @observers = []
    @ports = Hash.new { [].freeze }
    @links = []
    @hosts = []
    @paths = []
    @slices = []
end

def slices
    @slices
end
```
また、`topology_controller`から呼び出される`update_slice`メソッドは以下のような形で定義した。
```ruby
def update_slice(slice)
    @slices = slice
    maybe_send_handler :update_slice, slice, self
end
```
ここでは、@slicesに保持されているスライス情報を受け取ったsliceに変更している。


##### bin/slice
スライスの変更に関しては、必ずコマンドで操作をすることとなっている。そのため、sliceコマンドが入力された際にコマンドの種類に応じてスライスの情報を更新するような実装とした。
具体的には、各コマンド（listコマンドを除く）に以下の記述を追加した。
```ruby
update_slice(options[:socket_dir])
```
これによってupdate_sliceメソッドが呼び出され、コマンドが実行されるたびにスライスの情報を更新する。
ただし、slice.createを参考にしてプログラム先頭に以下の記述も行った。
```ruby
def self.update_slice(socket_dir)
    Trema.trema_process('RoutingSwitch', socket_dir).controller.update_slice
end
```

##### lib/view/vis.rb
スライス情報をテキストファイルに書き出すが、ホスト情報に付加して出力を行いたい。そこで、まず以下のように変更を加えた。
```ruby
 #host and slice
        file.printf("host\n")
        topology.hosts.each do |each|  #for all host
          slice_info = getSliceInfo(topology, each[0].to_s)
          file.printf("%s Host:%s %s\n",each[0].to_s, each[0].to_s, slice_info)
        end
```
`slice_info`という変数の中をホスト情報のあとに書き出すようにしている。この`slice_info`には`getSliceInfo`メソッドの返り値が入る。
`getSliceInfo`は以下のように定義した。
```ruby
 def getSliceInfo(topology, hostName)
      #print hostName + " for debug slice info \n"
      topology.slices.each do |each_slice|
        each_slice.each do |name, each_port|
          each_port.each do |each|
            if each == hostName
              return each_slice.to_s
            end
          end
        end
      end
    end
```
このメソッドでは、スライス情報の中から、受け取ったホストの所属するスライスを探し出し、その名前を返す。各スライスにはポート単位での管理が行われているため、要素を細かく取り出していく必要がある。そして、macアドレスを比較して、受け取ったホストのmacアドレスと一致していれば、そのスライスの名前を返している。

#####実行結果
まずターミナルで以下のようにコマンドを実行した。
```
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ ./bin/trema run lib/routing_switch.rb -c trema.conf -- --slicing
```
その後、別ターミナルで、以下のようなコマンドを実行した。
```
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/slice add foo
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/slice add foo2
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ ./bin/slice add_host --mac 11:11:11:11:11:11 --port 0x1:1 --slice foo
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ ./bin/slice add_host --mac 22:22:22:22:22:22 --port 0x4:1 --slice foo
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ ./bin/slice add_host --mac 33:33:33:33:33:33 --port 0x5:1 --slice foo2
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema send_packet --source host1 --dest host2
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema send_packet --source host2 --dest host1
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema send_packet --source host3 --dest host1
```
このとき、状況を確認するために以下のようにコマンドを実行した。

```
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema show_stats host1
Packets sent:
  192.168.0.1 -> 192.168.0.2 = 1 packet
Packets received:
  192.168.0.2 -> 192.168.0.1 = 1 packet
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema show_stats host2
Packets sent:
  192.168.0.2 -> 192.168.0.1 = 1 packet
Packets received:
  192.168.0.1 -> 192.168.0.2 = 1 packet
ensyuu2@ensyuu2-VirtualBox:~/ensyuu2/work8/sliceable-switch-owl$ bundle exec ./bin/trema show_stats host3
Packets sent:
  192.168.0.3 -> 192.168.0.1 = 1 packet
```
上記のことから、スライスfooにはhost1およびhost2が属し、スライスfoo2にはhost3が属しているという状況であると読み取れる。

このとき出力されるテキストファイル（topology.txt）のは以下のようになっている。
```
6 Switch:6
5 Switch:5
4 Switch:4
3 Switch:3
2 Switch:2
1 Switch:1
host
11:11:11:11:11:11 Host:11:11:11:11:11:11 foo
22:22:22:22:22:22 Host:22:22:22:22:22:22 foo
33:33:33:33:33:33 Host:33:33:33:33:33:33 foo2
link
100000 6 5
100001 5 4
100002 5 3
100003 5 1
100004 3 2
100005 1 2
100006 1 4
100007 11:11:11:11:11:11 1
100008 22:22:22:22:22:22 4
100009 33:33:33:33:33:33 5
```
上記より、ホストの情報のあとに正しくスライスの名前が入っていることがわかる。
#### vis.js による動的な確認



#### 実行結果





## メモ
実機の設定は前回の設定が残っている。
showコマンドで設定情報を確認すること。
設定用端末のネットワーク設定を逐一確認すること。

### 今後の修正点

* 世代毎の進化
* topology.txt のファイル監視

##参考文献
- デビッド・トーマス+アンドリュー・ハント(2001)「プログラミング Ruby」ピアソン・エデュケーション.  
- [テキスト: 15章 "ネットワークトポロジを検出する"](http://yasuhito.github.io/trema-book/#topology)  
- [Node.js 環境構築](https://liginc.co.jp/web/programming/node-js/85318)
- [Node.js プログラミング入門](http://libro.tuyano.com/index2?id=1115003)
- [Node.js ビギナーズブック](http://www.nodebeginner.org/index-jp.html#javascript-and-nodejs)
- [Vis.js Network Document](http://visjs.org/docs/network/)
