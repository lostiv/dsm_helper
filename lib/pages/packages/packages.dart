import 'package:dsm_helper/pages/packages/detail.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/bubble_tab_indicator.dart';
import 'package:dsm_helper/widgets/cupertino_image.dart';
import 'package:dsm_helper/widgets/label.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neumorphic/neumorphic.dart';

class Packages extends StatefulWidget {
  final String version;
  Packages(this.version);
  @override
  _PackagesState createState() => _PackagesState();
}

class _PackagesState extends State<Packages> with TickerProviderStateMixin {
  int packagesVersion = 1;
  int installedVersion = 1;
  TabController _tabController;
  List banners = [];
  List others = [];
  List packages = [];
  List betas = [];

  List categories = [];
  List installedPackages = [];
  List canUpdatePackages = [];
  List launchedPackages = [];

  List installedPackagesInfo = [];

  List volumes = [];
  bool loading = false;
  bool loadingAll = true;
  bool loadingInstalled = true;
  bool loadingOthers = true;
  List get allPackages {
    return packages + betas + others;
  }

  @override
  void initState() {
    String ver = widget.version;
    int end = ver.indexOf("-");
    var dsmVersion = ver.substring(4, end);
    List v = dsmVersion.split(".");
    if (v[0] == "6" && v[1] == "1") {
      installedVersion = 1;
      packagesVersion = 1;
    } else if (v[0] == "5") {
      packagesVersion = 1;
      installedVersion = 1;
    } else if (v[0] == "6" && v[1] == "2" && v.length == 2) {
      installedVersion = 1;
      packagesVersion = 2;
    } else {
      packagesVersion = 2;
      installedVersion = 2;
    }
    _tabController = TabController(initialIndex: 1, length: 3, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await Api.packages(version: packagesVersion);
    if (res['success']) {
      setState(() {
        banners = res['data']['banners'];
        if (res['data']['packages'] != null) {
          packages = res['data']['packages'];
        } else {
          packages = res['data']['data'];
        }
        if (res['data']['beta_packages'] != null) {
          betas = res['data']['beta_packages'];
          _tabController = TabController(initialIndex: 1, length: 4, vsync: this);
        }
        //
        categories = res['data']['categories'];
      });
      setState(() {
        loadingAll = false;
      });
    } else {
      Util.toast("数据加载失败");
      Navigator.of(context).pop();
      return;
    }
    getOthers();
    // getLaunchedPackages();
    getInstalledPackages();
    getVolumes();
  }

  getVolumes() async {
    var res = await Api.volumes();
    if (res['success']) {
      setState(() {
        volumes = res['data']['volumes'];
      });
    }
  }

  getOthers() async {
    print("获取第三方套件");
    var res = await Api.packages(others: true, version: packagesVersion);
    print("获取第三方套件end");
    if (res['success']) {
      setState(() {
        if (res['data']['packages'] != null) {
          others = res['data']['packages'];
        } else {
          others = res['data']['data'];
        }
        //
        loadingOthers = false;
      });
      calcInstalledPackage();
    }
  }

  // getLaunchedPackages() async {
  //   return;
  //   launchedPackages = [];
  //   print("获取运行中套件");
  //   var res = await Api.launchedPackages();
  //   print(res);
  //   print("获取运行中套件end");
  //   if (res['success']) {
  //     Map packages = res['data']['packages'];
  //     packages.forEach((key, value) {
  //       launchedPackages.add(key);
  //       setState(() {});
  //     });
  //     calcInstalledPackage();
  //   }
  // }

  getInstalledPackages() async {
    installedPackages = [];

    print("获取已安装套件");
    var res = await Api.installedPackages(version: installedVersion);
    print("获取已安装套件end");
    if (res['success']) {
      setState(() {
        installedPackagesInfo = res['data']['packages'];
        loadingInstalled = false;
      });
      calcInstalledPackage();
    } else {
      print(res);
      print("获取已安装套件失败");
    }
  }

  calcInstalledPackage() {
    canUpdatePackages = [];
    installedPackagesInfo.forEach((installedPackageInfo) {
      allPackages.forEach((package) {
        package['installed'] = package['installed'] ?? false;
        package['installed_version'] = package['installed_version'] ?? "";
        package['can_update'] = package['can_update'] ?? false;
        package['launched'] = package['launched'] ?? false;
        if (installedPackageInfo['id'] == package['id']) {
          package['installed'] = true;
          package['installed_version'] = installedPackageInfo['version'];
          package['can_update'] = Util.versionCompare(package['installed_version'], package['version']) < 0;
          package['additional'] = installedPackageInfo['additional'];
          if (package['installed']) {
            installedPackages.add(package);
          }
          if (package['can_update']) {
            canUpdatePackages.add(package);
          }
          if (package['additional'] != null && package['additional']['status'] == "running") {
            package['launched'] = true;
          } else if (launchedPackages.contains(package['id'])) {
            package['launched'] = true;
          }
        }
        setState(() {});
      });
    });
  }

  List<String> getCategoryName(List categoryIds) {
    List<String> name = [];
    if (categoryIds == null) {
      return [];
    }
    for (int i = 0; i < categoryIds.length; i++) {
      categories.forEach((category) {
        if (category['id'] == categoryIds[i]) {
          name.add(category['dname']);
        }
      });
    }
    return name;
  }

  Widget _buildButton(package) {
    Widget button;
    if (package['can_update'] == null || package['installed'] == null) {
      button = NeuCard(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        curveType: CurveType.convex,
        child: Text("获取中"),
      );
    } else if (package['can_update']) {
      button = NeuButton(
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(
                  builder: (context) {
                    return PackageDetail(package, method: "update");
                  },
                  settings: RouteSettings(name: "package_detail")))
              .then((_) async {
            // await getLaunchedPackages();
            await getInstalledPackages();
            setState(() {
              loading = false;
            });
          });
        },
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text("更新"),
      );
    } else if (package['installed']) {
      String text = "";
      if (package['launched'] && package['additional'] != null && package['additional']['startable']) {
        text = "停用";
      } else if (package['additional'] != null && package['additional']['startable']) {
        text = "启动";
      } else {
        text = "已安装";
      }
      button = NeuButton(
        onPressed: () async {
          if (text == "启动") {
            setState(() {
              loading = true;
            });
            var res = await Api.launchPackage(package['id'], package['dsm_apps'], "start");
            if (res['success']) {
              Util.toast("已启动");
              // await getLaunchedPackages();
              await getInstalledPackages();
              setState(() {
                loading = false;
              });
            }
          } else if (text == "停用") {
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
                          "停用套件",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          "确认要停用此套件？",
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
                                  setState(() {
                                    loading = true;
                                  });
                                  var res = await Api.launchPackage(package['id'], package['dsm_apps'], "stop");
                                  if (res['success']) {
                                    Util.toast("已停用");
                                    // await getLaunchedPackages();
                                    await getInstalledPackages();
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                },
                                decoration: NeumorphicDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                bevel: 5,
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  "停用",
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
          }
        },
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "$text",
          style: text == "启动"
              ? null
              : text == "停用"
                  ? TextStyle(color: Colors.red)
                  : TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      button = NeuButton(
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(
                  builder: (context) {
                    return PackageDetail(package, method: "install");
                  },
                  settings: RouteSettings(name: "package_detail")))
              .then((_) async {
            // await getLaunchedPackages();
            await getInstalledPackages();
            setState(() {
              loading = false;
            });
          });
        },
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text("安装套件"),
      );
    }
    return button;
  }

  Widget _buildUpdateItem(update) {
    String thumbnailUrl = update['thumbnail'].last;
    if (!thumbnailUrl.startsWith("http")) {
      thumbnailUrl = Util.baseUrl + thumbnailUrl;
    }
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(CupertinoPageRoute(
                builder: (context) {
                  return PackageDetail(update);
                },
                settings: RouteSettings(name: "package_detail")))
            .then((_) async {
          // await getLaunchedPackages();
          await getInstalledPackages();
          setState(() {
            loading = false;
          });
        });
      },
      child: NeuCard(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        margin: EdgeInsets.only(bottom: 20),
        curveType: CurveType.flat,
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        bevel: 20,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                height: 80,
                width: 80,
                alignment: Alignment.center,
                child: CupertinoExtendedImage(
                  thumbnailUrl,
                  width: 80,
                  height: 80,
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
                      "${update['dname']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      update['version'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _buildButton(update),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageItem(package, bool installed, {bool isBeta: false}) {
    String thumbnailUrl = "";
    if (package['thumbnail'].length > 0) {
      thumbnailUrl = package['thumbnail'].last;
      if (!thumbnailUrl.startsWith("http")) {
        thumbnailUrl = Util.baseUrl + thumbnailUrl;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(CupertinoPageRoute(
                builder: (context) {
                  return PackageDetail(package);
                },
                settings: RouteSettings(name: "package_detail")))
            .then((_) async {
          // await getLaunchedPackages();
          await getInstalledPackages();
          setState(() {
            loading = false;
          });
        });
      },
      child: NeuCard(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        curveType: CurveType.flat,
        decoration: NeumorphicDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        bevel: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 80,
                          child: CupertinoExtendedImage(
                            thumbnailUrl,
                            width: 80,
                          ),
                        ),
                      ),
                      if (isBeta || (package['additional'] != null && package['additional']['beta']))
                        Align(
                          alignment: Alignment.topRight,
                          child: Label(
                            "Beta",
                            Colors.lightBlueAccent,
                            fill: true,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 40,
                    child: Text(
                      "${package['dname']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    // "${package['category']}",
                    "${installed && package['additional']['updated_at'] != null ? package['additional']['updated_at'] : package['category'] is List && getCategoryName(package['category']).length > 0 ? getCategoryName(package['category']).join(",") : package['maintainer']}",
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.all(20), child: _buildButton(package)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "套件中心",
        ),
      ),
      body: Stack(
        children: [
          Column(
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
                      child: Text("已安装"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Text("全部套件"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Text("社群"),
                    ),
                    if (betas.length > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("Beta"),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                      child: loadingInstalled
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
                          : ListView(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              children: [
                                if (canUpdatePackages.length > 0)
                                  ListView.builder(
                                    itemBuilder: (content, i) {
                                      return _buildUpdateItem(canUpdatePackages[i]);
                                    },
                                    itemCount: canUpdatePackages.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                  ),
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: installedPackages.map((package) {
                                    return _buildPackageItem(package, true);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      child: loadingAll
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
                          : ListView(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              children: [
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: packages.map((package) {
                                    return _buildPackageItem(package, false);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      child: loadingOthers
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
                          : ListView(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              children: [
                                Wrap(
                                  runSpacing: 20,
                                  spacing: 20,
                                  children: others.map((package) {
                                    return _buildPackageItem(package, false);
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                    if (betas.length > 0)
                      ListView(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        children: [
                          Wrap(
                            runSpacing: 20,
                            spacing: 20,
                            children: betas.map((package) {
                              return _buildPackageItem(package, false, isBeta: true);
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (loading)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
              child: Center(
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
              ),
            ),
        ],
      ),
    );
  }
}
