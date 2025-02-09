import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/bubble_tab_indicator.dart';
import 'package:dsm_helper/widgets/label.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neumorphic/neumorphic.dart';
import 'package:vibrate/vibrate.dart';
import 'add_tracker.dart';

class DownloadDetail extends StatefulWidget {
  final String id;
  DownloadDetail(this.id);
  @override
  _DownloadDetailState createState() => _DownloadDetailState();
}

class _DownloadDetailState extends State<DownloadDetail> with TickerProviderStateMixin {
  TabController _tabController;
  bool loading = true;
  bool loadingTrackers = true;
  bool loadingPeers = true;
  bool loadingFiles = true;
  List trackers = [];
  List peers = [];
  List files = [];

  bool showAddTrackerButton = false;
  var task;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getTrackers() async {
    var res = await Api.downloadTracker(widget.id);
    if (res['success']) {
      setState(() {
        loadingTrackers = false;
        trackers = res['data']['items'];
      });
    }
  }

  getPeers() async {
    var res = await Api.downloadPeer(widget.id);
    if (res['success']) {
      setState(() {
        loadingPeers = false;
        peers = res['data']['items'];
      });
    }
  }

  getFiles() async {
    var res = await Api.downloadFile(widget.id);
    if (res['success']) {
      setState(() {
        loadingFiles = false;
        files = res['data']['items'];
      });
    }
  }

  handleTab() {
    if (_tabController.index == 2) {
      setState(() {
        showAddTrackerButton = true;
      });
      getTrackers();
    } else {
      setState(() {
        showAddTrackerButton = false;
      });
    }
    if (_tabController.index == 3) {
      getPeers();
    }
    if (_tabController.index == 4) {
      getFiles();
    }
  }

  getData() async {
    var res = await Api.downloadDetail(widget.id);
    setState(() {
      loading = false;
      if (res['success']) {
        task = res['data']['task'][0];
        if (task['type'] == "bt" && task['status'] == 2) {
          _tabController = TabController(length: 6, vsync: this);
          _tabController.addListener(handleTab);
        } else {
          _tabController = TabController(length: 2, vsync: this);
        }
      }
    });
  }

  Widget _buildFileItem(file) {
    return NeuCard(
      padding: EdgeInsets.all(20),
      curveType: CurveType.flat,
      decoration: NeumorphicDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      bevel: 20,
      child: Column(
        children: [
          Text(
            "${file['name']}",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text("${Util.formatSize(file['size_downloaded'])} / "),
              Text("${Util.formatSize(file['size'])}"),
              SizedBox(
                width: 10,
              ),
              Text(
                "${(file['size_downloaded'] * 100 / file['size']).toStringAsFixed(2)} %",
                style: TextStyle(color: Colors.blue),
              ),
              Spacer(),
              Label(
                file['priority'] == "normal"
                    ? "一般"
                    : file['priority'] == "high"
                        ? "高"
                        : "低",
                file['priority'] == "normal"
                    ? Colors.blue
                    : file['priority'] == "high"
                        ? Colors.orange
                        : Colors.grey,
                fill: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeerItem(peer) {
    return NeuCard(
      padding: EdgeInsets.all(20),
      curveType: CurveType.flat,
      decoration: NeumorphicDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      bevel: 20,
      child: Column(
        children: [
          Row(
            children: [
              Text("${peer['ip']}"),
              Spacer(),
              Text("${peer['client']}"),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text("进度：${(peer['progress'] * 100).toStringAsFixed(0)}%"),
              Spacer(),
              Icon(
                Icons.download_sharp,
                color: Colors.green,
                size: 16,
              ),
              Text(
                "${Util.formatSize(peer['speed_download'])}",
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(
                width: 10,
              ),
              Icon(
                Icons.upload_sharp,
                color: Colors.blue,
                size: 16,
              ),
              Text(
                "${Util.formatSize(peer['speed_upload'])}",
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerItem(tracker) {
    return NeuCard(
      padding: EdgeInsets.all(20),
      curveType: CurveType.flat,
      decoration: NeumorphicDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      bevel: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${tracker['url']}"),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                "种子数：${tracker['seeds'] >= 0 ? tracker['seeds'] : "-"}",
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                "Peer数：${tracker['peers'] >= 0 ? tracker['peers'] : "-"}",
                style: TextStyle(color: Colors.blue),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  "${tracker['status']}",
                  style: TextStyle(color: tracker['status'] == "Success" ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("任务详情"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: NeuButton(
              decoration: NeumorphicDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(10),
              bevel: 5,
              onPressed: () {
                Util.vibrate(FeedbackType.warning);
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return Material(
                      color: Colors.transparent,
                      child: NeuCard(
                        width: double.infinity,
                        padding: EdgeInsets.all(22),
                        bevel: 5,
                        curveType: CurveType.emboss,
                        decoration: NeumorphicDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              "确认删除",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Text(
                              "确认要删除此任务？",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                            ),
                            SizedBox(
                              height: 22,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: NeuButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      var res = await Api.downloadTaskAction([task['id']], "delete");
                                      if (res['success']) {
                                        Util.toast("任务删除成功");
                                        Navigator.of(context).pop(true);
                                      } else {
                                        Util.toast("任务删除失败，代码：${res['error']['code']}");
                                      }
                                    },
                                    decoration: NeumorphicDecoration(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    bevel: 5,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      "确认删除",
                                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: NeuButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                    decoration: NeumorphicDecoration(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    bevel: 5,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      "取消",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Image.asset(
                "assets/icons/delete.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: NeuCard(
                padding: EdgeInsets.all(50),
                curveType: CurveType.flat,
                decoration: NeumorphicDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                bevel: 20,
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              ),
            )
          : Column(
              children: [
                NeuCard(
                  width: double.infinity,
                  decoration: NeumorphicDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  curveType: CurveType.flat,
                  bevel: 10,
                  child: TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: BubbleTabIndicator(
                      indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                      shadowColor: Util.getAdjustColor(Theme.of(context).scaffoldBackgroundColor, -20),
                    ),
                    tabs: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("常规"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("传输信息"),
                      ),
                      if (task['type'] == "bt" && task['status'] == 2) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("Tracker服务器"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("Peer数"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("文件"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("预览"),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView(
                        children: [
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("文件名："),
                                Expanded(
                                  child: Text(task['title']),
                                ),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  Text("保存位置："),
                                  Expanded(
                                    child: Text(
                                      task['additional']['detail']['destination'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  Text("文件大小："),
                                  Expanded(
                                    child: Text(
                                      "${task['size'] > 0 ? Util.formatSize(task['size']) : "未取得"}",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("用户名："),
                                Text("${task['username']}"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("网址："),
                                Expanded(child: Text("${task['additional']['detail']['uri']}")),
                                NeuButton(
                                  onPressed: () async {
                                    ClipboardData data = new ClipboardData(text: task['additional']['detail']['uri']);
                                    Clipboard.setData(data);
                                    Util.toast("已复制到剪贴板");
                                  },
                                  decoration: NeumorphicDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.all(5),
                                  bevel: 5,
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Icon(
                                      Icons.copy,
                                      color: Color(0xffff9813),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("创建时间："),
                                Text(DateTime.fromMillisecondsSinceEpoch(task['additional']['detail']['created_time'] * 1000).format("Y-m-d H:i:s")),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("完成时间："),
                                Text(task['additional']['detail']['completed_time'] > 0 ? DateTime.fromMillisecondsSinceEpoch(task['additional']['detail']['completed_time'] * 1000).format("Y-m-d H:i:s") : "无法取得"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("预计等待时间："),
                                Text(task['additional']['detail']['waiting_seconds'] > 0 ? Util.timeRemaining(task['additional']['detail']['waiting_seconds']) : "无法取得"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        children: [
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("状态："),
                                Expanded(
                                  child: task['status'] == 1
                                      ? Text(
                                          "等待中",
                                          style: TextStyle(color: Colors.grey),
                                        )
                                      : task['status'] == 2
                                          ? Text(
                                              "${Util.formatSize(task['additional']['transfer']['speed_download'])}/s",
                                              style: TextStyle(color: Colors.lightBlueAccent),
                                            )
                                          : task['status'] == 3
                                              ? Text(
                                                  "已暂停",
                                                  style: TextStyle(color: Colors.grey),
                                                )
                                              : task['status'] == 5
                                                  ? Text(
                                                      "已完成",
                                                      style: TextStyle(color: Colors.green),
                                                    )
                                                  : task['status'] == 6
                                                      ? Text(
                                                          "检查中",
                                                          style: TextStyle(color: Colors.grey),
                                                        )
                                                      : task['status'] == 101
                                                          ? Text(
                                                              "错误",
                                                              style: TextStyle(color: Colors.red),
                                                            )
                                                          : task['status'] == 105
                                                              ? Text(
                                                                  "空间不足",
                                                                  style: TextStyle(color: Colors.red),
                                                                )
                                                              : task['status'] == 113
                                                                  ? Text(
                                                                      "重复的任务",
                                                                      style: TextStyle(color: Colors.red),
                                                                    )
                                                                  : Text(
                                                                      "代码：${task['status']}",
                                                                      style: TextStyle(color: Colors.red),
                                                                    ),
                                ),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  Text("已下载："),
                                  Expanded(
                                    child: Text(
                                      Util.formatSize(task['additional']['transfer']['size_downloaded']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  Text("已上传："),
                                  Expanded(
                                    child: Text(
                                      "${Util.formatSize(task['additional']['transfer']['size_uploaded'])} （${task['additional']['transfer']['size_downloaded'] > 0 ? (task['additional']['transfer']['size_uploaded'] / task['additional']['transfer']['size_downloaded'] * 100).toStringAsFixed(2) : "0"}%)",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  Text("进度："),
                                  Expanded(
                                    child: Text(
                                      "${task['size'] > 0 ? (task['additional']['transfer']['size_downloaded'] / task['size'] * 100).toStringAsFixed(2) : "0"}%",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("速度："),
                                Text("${task['additional']['transfer']['speed_download'] > 0 ? Util.formatSize(task['additional']['transfer']['speed_download']) : "无法取得"}"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Peer数："),
                                Expanded(child: Text("${task['additional']['detail']['total_peers'] > 0 ? task['additional']['detail']['total_peers'] : "无法取得"}")),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("分块总数："),
                                Expanded(child: Text("${task['additional']['detail']['total_pieces'] > 0 ? task['additional']['detail']['total_pieces'] : "无法取得"}")),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("已下载分块数："),
                                Text("${task['additional']['transfer']['downloaded_pieces']}"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("已做种时间："),
                                Text("${Util.timeRemaining(task['additional']['detail']['seed_elapsed'])}"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("开始时间："),
                                Text("${DateTime.fromMillisecondsSinceEpoch(task['additional']['detail']['started_time'] * 1000).format("Y-m-d H:i:s")}"),
                              ],
                            ),
                          ),
                          NeuCard(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: NeumorphicDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            curveType: CurveType.flat,
                            bevel: 20,
                            child: Row(
                              children: [
                                Text("剩余时间："),
                                Text("${task['additional']['transfer']['speed_download'] > 0 ? Util.timeRemaining(((task['size'] - task['additional']['transfer']['size_downloaded']) / task['additional']['transfer']['speed_download']).ceil()) : "无法取得"}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (task['type'] == "bt" && task['status'] == 2) ...[
                        loadingTrackers
                            ? Center(
                                child: NeuCard(
                                  padding: EdgeInsets.all(50),
                                  curveType: CurveType.flat,
                                  decoration: NeumorphicDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  bevel: 20,
                                  child: CupertinoActivityIndicator(
                                    radius: 14,
                                  ),
                                ),
                              )
                            : trackers.length == 0
                                ? Center(
                                    child: Text("无Tracker"),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildTrackerItem(trackers[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: trackers.length),
                        loadingPeers
                            ? Center(
                                child: NeuCard(
                                  padding: EdgeInsets.all(50),
                                  curveType: CurveType.flat,
                                  decoration: NeumorphicDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  bevel: 20,
                                  child: CupertinoActivityIndicator(
                                    radius: 14,
                                  ),
                                ),
                              )
                            : peers.length == 0
                                ? Center(
                                    child: Text("无Peer"),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildPeerItem(peers[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: peers.length),
                        loadingFiles
                            ? Center(
                                child: NeuCard(
                                  padding: EdgeInsets.all(50),
                                  curveType: CurveType.flat,
                                  decoration: NeumorphicDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  bevel: 20,
                                  child: CupertinoActivityIndicator(
                                    radius: 14,
                                  ),
                                ),
                              )
                            : files.length == 0
                                ? Center(
                                    child: Text("无文件"),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(20),
                                    itemBuilder: (context, i) {
                                      return _buildFileItem(files[i]);
                                    },
                                    separatorBuilder: (context, i) {
                                      return SizedBox(
                                        height: 20,
                                      );
                                    },
                                    itemCount: files.length),
                        Center(
                          child: Text("暂不支持预览"),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: showAddTrackerButton
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                        builder: (context) {
                          return AddTracker(widget.id);
                        },
                        settings: RouteSettings(name: "add_tracker")))
                    .then((res) {
                  if (res != null && res) {
                    getTrackers();
                  }
                });
              },
            )
          : null,
    );
  }
}
