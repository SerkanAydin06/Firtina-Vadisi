#!/usr/bin/env python3
"""Exercise editor preview in a disposable project using the normal editor loop."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot', help='Godot editor executable')
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if executable is None:
        parser.error(f'Godot executable not found: {args.godot}')
    source = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='firtina-editor-test-') as directory:
        sandbox = Path(directory)
        project = sandbox / 'project'
        shutil.copytree(source, project, ignore=shutil.ignore_patterns('.git', '.godot', '__pycache__'))
        plugin = project / 'addons' / 'preview_test'
        plugin.mkdir(parents=True)
        shutil.copy2(project / 'tests' / 'editor_preview.gd', plugin / 'runner.gd')
        (plugin / 'plugin.cfg').write_text(
            '[plugin]\nname="Preview test"\ndescription="Isolated editor regression"\n'
            'author="Firtina Vadisi"\nversion="1.0"\nscript="runner.gd"\n',
            encoding='utf-8',
        )
        config = project / 'project.godot'
        with config.open('a', encoding='utf-8') as stream:
            stream.write('\n[editor_plugins]\nenabled=PackedStringArray("res://addons/preview_test/plugin.cfg")\n')
        env = os.environ.copy()
        # Keep imports, editor settings, and user:// writes out of the real project/account.
        for key, folder in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache'), ('APPDATA', 'appdata'), ('LOCALAPPDATA', 'localappdata')]:
            (sandbox / folder).mkdir(exist_ok=True)
            env[key] = str(sandbox / folder)
        try:
            result = subprocess.run(
                [executable, '--headless', '--editor', '--path', str(project)],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, timeout=120,
            )
        except subprocess.TimeoutExpired as error:
            print(error.stdout.decode(errors='replace') if isinstance(error.stdout, bytes) else error.stdout or '')
            print('EDITOR PREVIEW: timed out', flush=True)
            return 1
        print(result.stdout, end='')
        # Also reject engine errors/warnings that do not set a failing exit status.
        clean = not any(marker in result.stdout for marker in ('ERROR:', 'WARNING:', 'SCRIPT ERROR:'))
        return 0 if result.returncode == 0 and clean and 'EDITOR PREVIEW: 0 failures' in result.stdout else 1


if __name__ == '__main__':
    raise SystemExit(main())
