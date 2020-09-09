import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product.dart';
import '../providers/products.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _descriptionFocusNode = FocusNode();
  final _form = GlobalKey<FormState>();
  var _editedProduct = Product(
    id: null,
    title: '',
    body: '',
    image: '',
  );
  var _initValues = {
    'title': '',
    'body': '',
    'image': '',
  };
  var _isInit = true;
  var _isLoading = false;

  File _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context).settings.arguments as int;
      if (productId != null) {
        _editedProduct = Provider.of<Products>(context, listen: false).findById(productId);
        _initValues = {
          'title': _editedProduct.title,
          'body': _editedProduct.body,
          'image': _editedProduct.image,
        };
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile.path);
    });
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }
    _form.currentState.save();
    setState(() {
      _isLoading = true;
    });
    if (_editedProduct.id != null) {
      await Provider.of<Products>(context, listen: false)
          .updateProduct(_editedProduct.id, _editedProduct, _image);
    } else {
      try {
        await Provider.of<Products>(context, listen: false)
            .addProduct(_editedProduct, _image);
      } catch (error) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text('エラー'),
                content: Text('サーバー側でエラーが発生しています。お手数ですが、運営までご連絡ください。'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Okay'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  )
                ],
              ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  Widget _buildImage() {
    if (_image == null) {
      if (_editedProduct.image == null) {
        return Text('画像を選択してください。');
      } else {
        return Image.network(_editedProduct.image, fit: BoxFit.cover,);
      }
    } else {
      return FittedBox(
        child: Image.file(
          _image,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('イベントの修正'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: getImage,
                      tooltip: '画像を選択',
                      child: Icon(Icons.add_a_photo),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(
                            top: 8,
                            right: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          // ネットワーきのimageの場合も先瀬尾
                          child: _buildImage()
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: _initValues['title'],
                      decoration: InputDecoration(labelText: 'タイトル'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_descriptionFocusNode);
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'タイトルを入力してください';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                            title: value,
                            body: _editedProduct.body,
                            image: _editedProduct.image,
                            id: _editedProduct.id,);
                      },
                    ),
                    TextFormField(
                      initialValue: _initValues['body'],
                      decoration: InputDecoration(labelText: '内容'),
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                      validator: (value) {
                        if (value.isEmpty) {
                          return '内容を入力してください。';
                        }
                        if (value.length < 10) {
                          return '内容は10文字から入力してください。';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          title: _editedProduct.title,
                          body: value,
                          image: _editedProduct.image,
                          id: _editedProduct.id,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
