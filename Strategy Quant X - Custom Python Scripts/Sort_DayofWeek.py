import os
import glob
import zipfile
import shutil

os.chdir("Random 1-80h Seasonality Tester/databanks/Long NQ/")

if not os.path.exists("0 - Sunday"):
	os.makedirs("0 - Sunday")
if not os.path.exists("1 - Monday"):
	os.makedirs("1 - Monday")
if not os.path.exists("2 - Tuesday"):
	os.makedirs("2 - Tuesday")
if not os.path.exists("3 - Wednesday"):
	os.makedirs("3 - Wednesday")
if not os.path.exists("4 - Thursday"):
	os.makedirs("4 - Thursday")
if not os.path.exists("5 - Friday"):
	os.makedirs("5 - Friday")
if not os.path.exists("6 - Saturday"):
	os.makedirs("6 - Saturday")

count = 0
for file in glob.glob("*.sqx"):
    count += 1
    zf = zipfile.ZipFile(file, 'r')
    for name in zf.namelist():
        if name == 'strategy_Portfolio.xml':
            f = zf.open(name)
            # here you do your magic with [f] : parsing, etc.
            # this will print out file contents
            x = f.read().decode("utf-8")
            matched_lines = str([line for line in x.split('\n') if 'key="#Day#"' in line])
            # Get last character of string i.e. char at index position len -1
            last_char = matched_lines[-13]
            if last_char == '0':
                shutil.copyfile(file, '0 - Sunday/' + file)
            if last_char == '1':
                shutil.copyfile(file, '1 - Monday/' + file)
            if last_char == '2':
                shutil.copyfile(file, '2 - Tuesday/' + file)
            if last_char == '3':
                shutil.copyfile(file, '3 - Wednesday/' + file)
            if last_char == '4':
                shutil.copyfile(file, '4 - Thursday/' + file)
            if last_char == '5':
                shutil.copyfile(file, '5 - Friday/' + file)
            if last_char == '6':
                shutil.copyfile(file, '6 - Saturday/' + file)
print('Copied ' + str(count) + ' sqx file(s)')