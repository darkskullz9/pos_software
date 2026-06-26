import 'package:flutter/material.dart';

class StringListEditor extends StatefulWidget {
  final String title;
  final List<String> values;
  final String hintText;
  final ValueChanged<List<String>> onChanged;

  const StringListEditor({
    super.key,
    required this.title,
    required this.values,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<StringListEditor> {
  final TextEditingController _controller = TextEditingController();

  late List<String> _values;

  @override
  void initState() {
    super.initState();
    _values = _sortedUnique(widget.values);
  }

  @override
  void didUpdateWidget(covariant StringListEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.values != widget.values) {
      _values = _sortedUnique(widget.values);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addValue() {
    final value = _controller.text.trim();

    if (value.isEmpty) return;

    final alreadyExists = _values.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$value" existe déjà')));
      return;
    }

    setState(() {
      _values = _sortedUnique([..._values, value]);
    });

    widget.onChanged(_values);
    _controller.clear();
  }

  void _removeValue(String value) {
    setState(() {
      _values = _values.where((item) => item != value).toList();
    });

    widget.onChanged(_values);
  }

  List<String> _sortedUnique(List<String> values) {
    final unique = values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    unique.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return unique;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addValue(),
              ),
            ),

            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addValue,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        if (_values.isEmpty)
          const Text('Aucune valeur configurée')
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _values.length,
              itemBuilder: (context, index) {
                final value = _values[index];

                return ListTile(
                  key: ValueKey('${widget.title}-$value'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(value),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeValue(value),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
