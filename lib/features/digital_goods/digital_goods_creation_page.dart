import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'digital_goods_service.dart';
import 'models.dart';

class DigitalGoodsCreationPage extends ConsumerStatefulWidget {
  final String userId;
  const DigitalGoodsCreationPage({required this.userId, Key? key}) : super(key: key);

  @override
  ConsumerState<DigitalGoodsCreationPage> createState() => _DigitalGoodsCreationPageState();
}

class _DigitalGoodsCreationPageState extends ConsumerState<DigitalGoodsCreationPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  List<PackAsset> assets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Overlay/Emoji Pack')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (v) => setState(() => name = v),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => description = v),
            ),
            // TODO: Asset upload UI
            ElevatedButton(
              child: Text('Create'),
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final creation = UserCreation(
                    id: UniqueKey().toString(),
                    type: PackType.overlay, // or PackType.emoji
                    name: name,
                    description: description,
                    assets: assets,
                    isPublished: false,
                    publishedPackId: null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await DigitalGoodsService().createUserCreation(
                    userId: widget.userId,
                    creation: creation,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Creation saved!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
