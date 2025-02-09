import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:dsm_helper/pages/download/download_setting.dart';
import 'package:dsm_helper/widgets/transparent_router.dart';
import 'package:dsm_helper/pages/common/preview.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:neumorphic/neumorphic.dart';
import 'package:vibrate/vibrate.dart';

class DownloadInfo {
  String taskId;
  DownloadTaskStatus status;
  int progress;
  String url;
  String filename;
  String savedDir;
  int timeCreated;

  DownloadInfo({@required this.taskId, @required this.status, @required this.progress, @required this.url, @required this.filename, @required this.savedDir, @required this.timeCreated});
  factory DownloadInfo.formTask(DownloadTask task) {
    return DownloadInfo(taskId: task.taskId, status: task.status, progress: task.progress, url: task.url, filename: task.filename, savedDir: task.savedDir, timeCreated: task.timeCreated);
  }
  @override
  String toString() => "DownloadInfo(taskId: $taskId, status: $status, progress: $progress, url: $url, filename: $filename, savedDir: $savedDir, timeCreated: $timeCreated)";
}

class Download extends StatefulWidget {
  Download({key}) : super(key: key);
  @override
  DownloadState createState() => DownloadState();
}

class DownloadState extends State<Download> {
  List<DownloadInfo> tasks = [];
  bool loading = true;
  List<DownloadInfo> selectedTasks = [];
  Timer timer;
  bool multiSelect = false;

  ReceivePort _port = ReceivePort();
  @override
  void initState() {
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    getData();
    super.initState();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    print('Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      print('UI Isolate Callback: $data');
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (tasks != null && tasks.isNotEmpty) {
        tasks.forEach((task) {
          if (task.taskId == id) {
            setState(() {
              task.status = status;
              task.progress = progress;
            });
          }
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  getData() async {
    List<DownloadTask> downloadTasks = await FlutterDownloader.loadTasks();
    tasks = downloadTasks.map((e) => DownloadInfo.formTask(e)).toList();
    setState(() {
      loading = false;
    });
    //如果存在下载中任务，每秒刷新一次
    // if (tasks.where((task) => task.status == DownloadTaskStatus.running || task.status == DownloadTaskStatus.enqueued || task.status == DownloadTaskStatus.undefined).length > 0) {
    //   if (timer == null) {
    //     timer = Timer.periodic(Duration(seconds: 1), (timer) {
    //       getData();
    //     });
    //   }
    // } else {
    //   timer?.cancel();
    // }
  }

  Future<bool> onWillPop() {
    if (multiSelect) {
      setState(() {
        multiSelect = false;
        selectedTasks = [];
      });
    } else {
      print("可以返回");
      return Future.value(true);
    }

    return Future.value(false);
  }

  Widget _buildDownloadStatus(DownloadTaskStatus status, int progress) {
    if (status == DownloadTaskStatus.complete) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.lightGreen,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "下载完成",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else if (status == DownloadTaskStatus.failed) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "下载失败",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else if (status == DownloadTaskStatus.canceled) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "取消下载",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else if (status == DownloadTaskStatus.paused) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "暂停下载",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else if (status == DownloadTaskStatus.running) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.lightBlueAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "$progress%",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else if (status == DownloadTaskStatus.enqueued) {
      return NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        margin: EdgeInsets.only(bottom: 3),
        bevel: 0,
        decoration: NeumorphicDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "等待下载",
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildTaskItem(DownloadInfo task) {
    FileType fileType = Util.fileType(task.filename);
    // String path = file['path'];
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20, right: 20),
      child: NeuButton(
        onLongPress: () {
          Util.vibrate(FeedbackType.light);
          setState(() {
            multiSelect = true;
            selectedTasks.add(task);
          });
        },
        onPressed: () async {
          // print(task.savedDir + "/" + task.filename);
          // return;
          if (multiSelect) {
            setState(() {
              if (selectedTasks.contains(task)) {
                selectedTasks.remove(task);
              } else {
                selectedTasks.add(task);
              }
            });
          } else {
            if (fileType == FileType.image) {
              //获取当前目录全部图片文件
              List<String> images = [];
              int index = 0;
              for (int i = 0; i < tasks.length; i++) {
                if (task.status == DownloadTaskStatus.complete && Util.fileType(task.filename) == FileType.image) {
                  images.add(tasks[i].savedDir + "/" + tasks[i].filename);
                  if (tasks[i] == task) {
                    index = images.length - 1;
                  }
                }
              }
              Navigator.of(context).push(TransparentPageRoute(
                  pageBuilder: (context, _, __) {
                    return PreviewPage(
                      images,
                      index,
                      network: false,
                    );
                  },
                  settings: RouteSettings(name: "preview_image")));
            } else {
              var result = await FlutterDownloader.open(taskId: task.taskId);
              if (!result) {
                Util.toast("不支持打开此文件");
              }
            }
          }
        },
        // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        bevel: 8,
        child: Row(
          children: [
            SizedBox(
              width: 20,
            ),
            Hero(
              tag: task.savedDir + "/" + task.filename,
              child: FileIcon(
                fileType,
                thumb: task.status == DownloadTaskStatus.complete ? task.savedDir + "/" + task.filename : null,
                network: false,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.filename,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    DateTime.fromMillisecondsSinceEpoch(task.timeCreated).format("Y/m/d H:i:s"),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.headline5.color),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  _buildDownloadStatus(task.status, task.progress),
                ],
              ),
            ),
            SizedBox(
              width: 10,
            ),
            multiSelect
                ? NeuCard(
                    decoration: NeumorphicDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    curveType: selectedTasks.contains(task) ? CurveType.emboss : CurveType.flat,
                    padding: EdgeInsets.all(5),
                    bevel: 5,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: selectedTasks.contains(task)
                          ? Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Color(0xffff9813),
                            )
                          : null,
                    ),
                  )
                : NeuButton(
                    onPressed: () {
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
                                    "选择操作",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(
                                    height: 22,
                                  ),
                                  NeuButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent: true);
                                      await getData();
                                    },
                                    decoration: NeumorphicDecoration(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    bevel: 5,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      "删除",
                                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  NeuButton(
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
                    padding: EdgeInsets.only(left: 5, right: 3, top: 4, bottom: 4),
                    decoration: NeumorphicDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    bevel: 2,
                    child: Icon(
                      CupertinoIcons.right_chevron,
                      size: 18,
                    ),
                  ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: multiSelect
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    multiSelect = false;
                    selectedTasks = [];
                  });
                },
                child: Icon(Icons.close))
            : null,
        title: Text(
          "下载",
        ),
        actions: [
          if (multiSelect)
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
                  if (selectedTasks.length == tasks.length) {
                    selectedTasks = [];
                  } else {
                    selectedTasks = [];
                    tasks.forEach((task) {
                      selectedTasks.add(task);
                    });
                  }

                  setState(() {});
                },
                child: Image.asset(
                  "assets/icons/select_all.png",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          if (Platform.isAndroid)
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
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) {
                        return DownloadSetting();
                      },
                      settings: RouteSettings(name: "download_setting"),
                    ),
                  );
                },
                child: Image.asset(
                  "assets/icons/setting.png",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? Center(
              child: CupertinoActivityIndicator(),
            )
          : tasks.length > 0
              ? Stack(
                  children: [
                    ListView(
                      children: tasks.reversed.map(_buildTaskItem).toList(),
                    ),
                    AnimatedPositioned(
                      bottom: selectedTasks.length > 0 ? 0 : -100,
                      duration: Duration(milliseconds: 200),
                      child: NeuCard(
                        margin: EdgeInsets.all(20),
                        padding: EdgeInsets.all(10),
                        width: MediaQuery.of(context).size.width - 40,
                        height: 62,
                        bevel: 20,
                        curveType: CurveType.flat,
                        decoration: NeumorphicDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () async {
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
                                              "确认要删除${selectedTasks.length}个下载任务？",
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
                                                      for (DownloadInfo task in selectedTasks) {
                                                        await FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent: true);
                                                      }
                                                      getData();
                                                      setState(() {
                                                        multiSelect = false;
                                                        selectedTasks = [];
                                                      });
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
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/icons/delete.png",
                                    width: 25,
                                  ),
                                  Text(
                                    "删除",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("暂无下载任务"),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "可在[文件]中点击文件右侧 > 将文件下载到手机",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
    );
  }
}
