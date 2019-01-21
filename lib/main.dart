import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _controlador = TextEditingController();

  List _lista = [];

  Map<String, dynamic> _lastRemoved; //ultimo item removido
  int _lastRemovedPos; //posicao do ultimo item removido

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _lista = json.decode(data);
      });
    });
  }

  void _addList() {
    setState(() {
      Map<String, dynamic> registro = new Map();
      registro["title"] = _controlador.text;
      _controlador.text = "";
      registro["ok"] = false;
      _lista.add(registro);
      _saveData();
    });
  }

  Future<num> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
setState(() {
  _lista.sort((a, b) {
    if (a["ok"] && !b["ok"])
      return 1;
    else if (!a["ok"] && b["ok"])
      return -1;
    else
      return 0;
  });

  _saveData();
});

return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _controlador,
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.black)),
                )),
                RaisedButton(
                  color: Colors.black,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: _addList,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _lista.length,
                itemBuilder: buildItem),
          )),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    //Dismissible = widget que permite que ao arrastar, deleta o item
    return Dismissible(
      //pra tornar o item único
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_lista[index]["title"]),
        value: _lista[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_lista[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _lista[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_lista[index]);
          _lastRemovedPos = index;
          _lista.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _lista.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/data.json");
  }

  Future<File> _saveData() async {
    //Pegando a lista, transformando em json e armazenando em uma string 
    String data = json.encode(_lista);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
