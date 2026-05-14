import pathlib
path = pathlib.Path(r'C:\Users\laptop\StudioProjects\Smart tv app\lib\screens\player_screen.dart')
path.write_text(path.read_text('utf-8'), 'utf-8')
print('Lines:', len(path.read_text().splitlines()))
