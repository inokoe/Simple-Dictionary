import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'dart:async';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class Dictonary extends StatefulWidget {
  const Dictonary({Key? key}) : super(key: key);

  @override
  State<Dictonary> createState() => _DictonaryState();
}

class _DictonaryState extends State<Dictonary> {
  final TextEditingController _word = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  String x = 'Welcome';
  String y = '~fu(`.`@)';
  bool isWord = false;
  bool isSentence = false;
  void lookup(value) async {
    x = '';
    y = '';
    isSentence = false;
    isWord = false;
    String ans = '';
    try {
      HttpClient httpClient = HttpClient();
      String url = "https://open.iciba.com/huaci/dict.php?word=${Uri.encodeQueryComponent(value)}";
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      if (kDebugMode) {
        print('debug: $url');
      }
      //使用iPhone的UA
      request.headers.add(
        "user-agent",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
      );
      //等待连接服务器（会将请求信息发送给服务器）
      HttpClientResponse response = await request.close();
      //读取响应内容
      ans = await response.transform(utf8.decoder).join();
      var document = parse(ans);
      int? len = document.body?.getElementsByTagName('strong').length;
      if (len != null && len > 0) {
        x = '英 ';
        for (int i = 0; i < len; i++) {
          x += (document.body?.getElementsByTagName('strong')[i].innerHtml)!;
          if (i == 2 && i != len - 1) {
            x += ' 美 ';
          }
          if (i == len - 1 && !x.contains('美')) {
            x = x.replaceFirst('英', '音标');
          }
        }
        isWord = true;
      } else if (ans.toString().indexOf('icIBahyI-suggest2') > 0) {
        len = document.body?.getElementsByTagName('div').length;
        for (int i = 0; i < len!; i++) {
          // print((document.body?.getElementsByTagName('div')[i].outerHtml));
          if ((document.body
                  ?.getElementsByTagName('div')[i]
                  .outerHtml
                  .indexOf('icIBahyI-suggest2'))! >
              0) {
            y = (document.body?.getElementsByTagName('div')[i].innerHtml)!;
            if (y.indexOf('div') > 0) continue;
            x = '翻译结果如下';
            isSentence = true;
            break;
          }
        }
      } else {
        x = '';
        isWord = true;
      }
      len = document.body?.getElementsByTagName('p').length;
      if (len != null && isWord) {
        y = '';
        for (int i = 0; i < len; i++) {
          String tp = (document.body?.getElementsByTagName('p')[i].innerHtml)!;
          if (tp.indexOf('label') > 0) {
            var doc = parse(tp);
            // print(doc.getElementsByTagName('span')[0].innerHtml);
            if (!doc
                .getElementsByTagName('span')[0]
                .innerHtml
                .contains('label')) {
              y += doc.getElementsByTagName('span')[0].innerHtml;
            }
            int labelLen = doc.getElementsByTagName('label').length;
            for (int h = 0; h < labelLen; h++) {
              int aLen = (doc
                  .getElementsByTagName('label')[h]
                  .getElementsByTagName('a')
                  .length);
              if (aLen == 0) {
                y += ' ${doc.getElementsByTagName('label')[h].innerHtml}';
              } else {
                for (int a = 0; a < aLen; a++) {
                  y +=
                      '${doc.getElementsByTagName('label')[h].getElementsByTagName('a')[a].innerHtml} , ';
                }
              }
              if (h == labelLen - 1) {
                if (y[y.length - 2] == ',') {
                  y = y.substring(0, y.length - 3);
                }
              }
            }
          }
          if (i != len - 1) {
            y += '\r\n';
          }
        }
      }
      //输出响应头
      // print(response.headers);
      //关闭client后，通过该client发起的所有请求都会中止。
      httpClient.close();
      if (x.trim() == y.trim() && y.trim() == '') {
        x = '这不是一个标准单词/词组';
        y = '请再次尝试';
      }
      if (x.trim() == '' && y.trim() != '') x = '词组';
    } catch (e) {
      x = '请求失败';
      y = '网络连接错误或者接口失效';
    } finally {
      y = y.replaceAll('\\', '');
      update(x, y);
    }
  }

  void update(w, e) {
    setState(() {
      x = w;
      y = e;
    });
  }

  void audioPlayer() async {
    if (!(isWord || isSentence)) return;
    final player = AudioPlayer();
    String searchAudio = '';
    if (isWord) {
      if (x.contains('词组') || x.contains('音标')) {
        searchAudio = y;
      } else {
        searchAudio = _word.text.toString();
      }
    } else {
      RegExp regWord = RegExp('[A-Za-z]+');
      if (regWord.hasMatch(y)) {
        searchAudio = y;
      } else {
        searchAudio = _word.text.toString();
      }
    }
    try{
      await player.setSourceUrl(
          'http://dict.youdao.com/dictvoice?audio=${Uri.encodeQueryComponent(searchAudio)}'); // equivalent to setSource(UrlSource(url));
      if (kDebugMode) {
        print(
            'http://dict.youdao.com/dictvoice?audio=${Uri.encodeQueryComponent(searchAudio)}');
      }
      await player.resume();
    }catch(e){
      if(kDebugMode){
        print(e);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: TextField(
                  controller: _word,
                  focusNode: _commentFocus,
                  autofocus: true,
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: 'Search a word !'),
                  onSubmitted: (value) {
                    lookup(value.toLowerCase().trim());
                    FocusScope.of(context).requestFocus(_commentFocus);
                  },
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 20.0),
                  child: Column(
                    children: [
                      ListTile(
                        // leading: Icon(Icons.message),
                        title: Text(
                          x,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          y,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 9,
                          style: const TextStyle(fontSize: 30),
                        ),
                        trailing: const Icon(
                          Icons.audiotrack,
                          size: 50,
                        ),
                        onTap: () {
                          audioPlayer();
                          if (isSentence || isWord) {
                            Clipboard.setData(ClipboardData(text: y));
                          }
                          FocusScope.of(context).requestFocus(_commentFocus);
                        },
                      ),
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }
}
