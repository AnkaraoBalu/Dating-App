import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../widgets/profile_widgets.dart';
import 'profile_interests_screen.dart';

class ProfileAboutMeScreen extends StatefulWidget {
  const ProfileAboutMeScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileAboutMeScreen> createState() => _ProfileAboutMeScreenState();
}

class _ProfileAboutMeScreenState extends State<ProfileAboutMeScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _bio;
  late final List<
    ({TextEditingController question, TextEditingController answer})
  >
  _prompts;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile!;
    _bio = TextEditingController(text: p.text('bio'));
    _prompts = p.prompts
        .map(
          (p) => (
            question: TextEditingController(text: p['question']),
            answer: TextEditingController(text: p['answer']),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _bio.dispose();
    for (final p in _prompts) {
      p.question.dispose();
      p.answer.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final prompts = _prompts
        .map(
          (p) => {
            'question': p.question.text.trim(),
            'answer': p.answer.text.trim(),
          },
        )
        .toList();
    if (prompts.map((p) => p['question']).toSet().length != prompts.length) {
      profileNotice(context, 'Each prompt needs a different question.');
      return;
    }
    await widget.controller.update({'bio': _bio.text.trim()});
    await widget.controller.savePrompts(prompts);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfileInterestsScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    step: 3,
    bottom: ProfileSaveButton(controller: widget.controller, onSave: _save),
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const ProfileSection(
            'About Me',
            subtitle: 'Write a short bio about yourself',
          ),
          TextFormField(
            controller: _bio,
            maxLength: 200,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Your favorite things, your kind of day, what makes you smile…',
            ),
          ),
          const ProfileSection(
            'Prompts',
            subtitle: 'Give someone a reason to start a conversation',
          ),
          for (var i = 0; i < _prompts.length; i++) ...[
            Row(
              children: [
                Expanded(child: Text('Prompt ${i + 1}')),
                IconButton(
                  tooltip: 'Remove prompt',
                  onPressed: () {
                    final removed = _prompts[i];
                    setState(() => _prompts.removeAt(i));
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      removed.question.dispose();
                      removed.answer.dispose();
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            TextFormField(
              controller: _prompts[i].question,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Question'),
              validator: _required,
            ),
            TextFormField(
              controller: _prompts[i].answer,
              maxLength: 150,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Your answer'),
              validator: _required,
            ),
            const SizedBox(height: 12),
          ],
          if (_prompts.length < 5)
            OutlinedButton.icon(
              onPressed: () => setState(
                () => _prompts.add((
                  question: TextEditingController(),
                  answer: TextEditingController(),
                )),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add a prompt'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Add a question and answer, or remove this prompt.'
      : null;
}
