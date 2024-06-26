import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart'as http;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Stepper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  int _currentStep =0;
  final myController = TextEditingController();
  final myController2 = TextEditingController();
  // ユーザの情報を格納する辞書配列
  Map<String,dynamic> user = {
    'trainer':nullptr,
    'email':nullptr,
    'birthdate':nullptr,
    'origin':nullptr,
    'pokeimage':[],
    'pokename':[]
  };
  String name = "";
  String juusyo1 = '';
  String email= "";
  String aisatu = "この入力内容でいいですか？";
  String dateText = "";
  // 名前、趣味の入力欄のウィジェット
  Widget NameInput(){

    return Container(
      width: double.infinity,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'トレーナ名',
            ),
            onChanged: (text) {
              // TODO: ここで取得したtextを使う
              // トレーナー名
              name = text;
              user['trainer']= name;
            },

          ),
          TextField(
            controller: myController,
            decoration: InputDecoration(
              hintText: 'メールアドレス',
            ),
            onChanged: (text){
              // メールアドレス
              email = text;
              user['email'] = email;
            },
          ),

        ],
      ),
    );
  }

  Widget juusyoKensaku(){
    // 住所などが文字列で入る
    List<String> items = [];
    // エラーメッセージ用の変数
    String errorMessage='';

    // 非同期処理の書き方↓
    Future<void> loadZipCode(String zipCode)async{
      setState(() {
        errorMessage= 'APIレスポンス待ち';
      });
      final response = await http.get(
        // ↓住所検索のAPIのURL
          Uri.parse('https://zipcloud.ibsnet.co.jp/api/search?zipcode=$zipCode')
      );
      //   失敗の場合成功の時の値が２００だから
      if(response.statusCode != 200){
        setState(() {
          errorMessage = 'エラーが発生しました:${response.statusCode}';
        });
        return;
      }
      // 成功の場合
      final body = json.decode(response.body) as Map<String,dynamic>;
      final results = (body['results'] ?? [])as List<dynamic>;

      if(results.isEmpty){
        setState(() {
          errorMessage ='そのような郵便番号の住所はありません';
        });
      }else{
        setState(() {
          errorMessage="";
          juusyo1 = results[0]['address1']+results[0]['address2'];
          user['origin']=juusyo1;

        });
      }
    }

    return Container(child: Column(
      children: [
        TextField(
          inputFormatters: [
            LengthLimitingTextInputFormatter(7),
            // 数字以外入力できなくなる
            FilteringTextInputFormatter.digitsOnly
          ],
          controller: myController2,
          keyboardType: TextInputType.number,
          // 変更を検知するためのプロパティ入力欄に入力したり変えたりしたりしたときに動く
          onChanged: (value){
            if(value.isNotEmpty){
              loadZipCode(value);
            }
          },
        ),
        Title(color: Colors.black, child: Text('トレーナーの出身地')),
        Text('$juusyo1')
      ],
    ),
    );

  }
  // 生年月日を入力させるウィジェット
  Widget birthday(){
    return ElevatedButton(
        onPressed: (){
          DatePicker.showDatePicker(
            context,
            // 選択できる日時の範囲
            minTime: DateTime(1924, 1, 1),
            maxTime: DateTime(2030, 12, 31),
            // 関数(onChangedなど)は省略
            //言語
            locale: LocaleType.jp,
          );

        },
        child: Text('生年月日'));
  }
  Widget customDoneButton() {
    return GestureDetector(
      onTap: () {
        null;
      },
      child: Text(
        '完了',
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (int step)=> setState(()=>_currentStep=step),
          // Continue押したときの処理
          onStepContinue:_currentStep<2?()=>setState(()=> _currentStep+=1):null,
          // Cancel押したときの処理
          onStepCancel: _currentStep>0?()=>setState(()=>_currentStep-=1):null,

          steps: <Step>[
            Step(
              title: const Text('トレーナ登録'),
              content: Column(children: [
                Text('トレーナ名とメールアドレス、出身地を入力'),
                NameInput(),
                juusyoKensaku(),
                
              ]),
              isActive: _currentStep>=1,
              state: _currentStep>=0?StepState.complete:StepState.disabled,
            ),
            Step(
              title: const Text('ポケモンをゲット'),
              content: Column(
                children: [
                    Text('${name}のポケモンをゲットしよう！！'),
                    Text('生年月日を入力してね'),
                    birthday(),
                  Title(color: Colors.black, child: Text('あなたがゲットしたポケモン',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),))
                ],
              ),

              isActive: _currentStep>=2,
              state: _currentStep>=1?StepState.complete:StepState.disabled,
            ),
            Step(
              title: const Text('ステップ3'),
              content: Column(
                children: [
                  Title(color: Colors.black, child: Text('$aisatu')),
                  // Flutter1.22以降のみ
                  ElevatedButton(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.lightBlueAccent,
                            Colors.lightBlue,
                            Colors.blue,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Text('入力完了'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0),
                    ),
                    onPressed: () {
                      setState(() {
                        aisatu='お疲れ様';
                      });
                    },
                  ),
                  Text('あなたのお名前：${name}'),
                  Text('あなたの住所：${juusyo1}'),
                  Text('あなたの趣味：${email}')

                ],
              ),


              isActive: _currentStep>=3,
              state: _currentStep>=2?StepState.complete:StepState.disabled,
            ),


          ],

        )
    );
  }
}


