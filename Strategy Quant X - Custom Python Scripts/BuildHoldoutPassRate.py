import os
import glob
import zipfile
import shutil
import copy
import colorama
from colorama import init, Fore, Back, Style

symbol = {
  "name": "",
  "taskName": [],
  "count": [],
  "countHoldout": [],
  "filtered": [],
  "filteredHoldout": []
}

symbols = []

# extract the symbol from .sqx file xml and add one that given symbol column
def getSymbol(file, dirsTask, column, taskNum):
    zf = zipfile.ZipFile(file, 'r')
    for name in zf.namelist():
        if name == 'lastSettings.xml':
            f = zf.open(name)
            x = f.read().decode("utf-8")
            # extract symbol from selected line found in xml
            pos = x.find('<Chart symbol=')
            symbolName = x[pos:pos + 100].split('"')[1]
            # find symbol in array
            for s in symbols:
                if s["name"] == symbolName:
                    # set column 
                    setColumn(s, dirsTask, column, taskNum)
                    return
            # no symbol found add to array
            symbols.append(copy.deepcopy(symbol))
            symbols[len(symbols) - 1]["name"] = symbolName
            # set column
            setColumn(symbols[len(symbols) - 1], dirsTask, column, taskNum)
            return
            
# helper function to set a symbol's column
def setColumn(symbolDict, dirsTask, column, taskNum):
    # add a new row for each column if on next task
    if len(symbolDict["taskName"]) <= taskNum:
        symbolDict["taskName"].append(dirsTask)
        symbolDict["count"].append(0)
        symbolDict["countHoldout"].append(0)
        symbolDict["filtered"].append(0)
        symbolDict["filteredHoldout"].append(0)
    # add 1 to the selected column
    symbolDict[column][taskNum] += 1
    
# divide by zero safety
def zero_div(x, y):
    if y: return x / y
    else: return 0


init(convert=True)
os.chdir("C:/Users/Kevin/Desktop/Algo Business/SQX/Seasonality v0.5/SQX Debug Projects/")

# for each sector count the data for each column
for dirsSectors in glob.glob("*/", recursive = True):
    lastTestedCount = lastTestedCount_f = 0;
    reduction = reduction_f = ""
    #print the header rows
    print(Back.WHITE + Fore.BLUE + '{:^146s}'.format(dirsSectors[0:-1]) + Style.RESET_ALL)
    print(Back.WHITE + Fore.BLACK + '{:40s} {:15s} {:16s} {:14s}        {:15s} {:16s} {:17s}'.format('Task Name', 'Tested', 'Holdout Pass', 'Holdout Pass %', 'Filtered', 'F Holdout Pass', 'F Holdout Pass %') + Style.RESET_ALL)
    for dirsTask in glob.glob(dirsSectors + "*/", recursive = True):
        count = countHoldout = filtered = filteredHoldout = 0
        # loop to count files in the directory
        for file in glob.glob(dirsTask + "*.sqx"):
            count += 1
        for file in glob.glob(dirsTask + "Holdout/*.sqx"):
            countHoldout += 1
        for file in glob.glob(dirsTask + "Filtered/*.sqx"):
            filtered += 1
        for file in glob.glob(dirsTask + "FilteredHoldout/*.sqx"):
            filteredHoldout += 1
        
        # calculated Task Tested Reduction since last Task
        if lastTestedCount <= 0:
            reduction = ""
        else:
            reduction = " (" + str(round((1 - count/lastTestedCount) * 100)) + '%' + ")"
        lastTestedCount = count;
        if lastTestedCount_f <= 0:
            reduction_f = ""
        else:
            reduction_f = " (" + str(round((1 - filtered/lastTestedCount_f) * 100)) + '%' + ")"
        lastTestedCount_f = filtered;
        
        # print each task row
        print('{:40s} {:15s} {:16s} {:14s}    {:1s}    {:15s} {:16s} {:17s}'.format(dirsTask.replace(dirsSectors, '')[0:-1], str(count) + reduction, str(countHoldout), str(round(zero_div(countHoldout, count) * 100,2)) + '%', Fore.CYAN + Style.BRIGHT, str(filtered) + reduction_f, str(filteredHoldout), str(round(zero_div(filteredHoldout, filtered) * 100,2)) + '%') + Style.RESET_ALL)
    # print the footer row
    print('')
    
print('\n\n')
# for each symbol collect the data for each column
for dirsSectors in glob.glob("*/", recursive = True):
    taskNum = 0
    for dirsTask in glob.glob(dirsSectors + "*/", recursive = True):
        # loop to count files in the directory saved per symbol
        for file in glob.glob(dirsTask + "*.sqx"):
            getSymbol(file, dirsTask.replace(dirsSectors, '')[0:-1], "count", taskNum)
        for file in glob.glob(dirsTask + "Holdout/*.sqx"):
            getSymbol(file, dirsTask.replace(dirsSectors, '')[0:-1], "countHoldout", taskNum)
        for file in glob.glob(dirsTask + "Filtered/*.sqx"):
            getSymbol(file, dirsTask.replace(dirsSectors, '')[0:-1], "filtered", taskNum)
        for file in glob.glob(dirsTask + "FilteredHoldout/*.sqx"):
            getSymbol(file, dirsTask.replace(dirsSectors, '')[0:-1], "filteredHoldout", taskNum)
        taskNum += 1
        
# read each symbol and print data from symbol dictionary array
for s in symbols:
    lastTestedCount = lastTestedCount_f = 0;
    reduction = reduction_f = ""
    #print the header rows
    print(Back.WHITE + Fore.MAGENTA + '{:^146s}'.format(s["name"]) + Style.RESET_ALL)
    print(Back.WHITE + Fore.BLACK + '{:40s} {:15s} {:16s} {:14s}        {:15s} {:16s} {:17s}'.format('Task Name', 'Tested', 'Holdout Pass', 'Holdout Pass %', 'Filtered', 'F Holdout Pass', 'F Holdout Pass %') + Style.RESET_ALL)
    # for each task per symbol print out the table
    for taskNum in range(0, len(s["taskName"])):
        # calculated Task Tested Reduction since last Task
        if lastTestedCount <= 0:
            reduction = ""
        else:
            reduction = " (" + str(round((1 - s["count"][taskNum]/lastTestedCount) * 100)) + '%' + ")"
        lastTestedCount = s["count"][taskNum];
        if lastTestedCount_f <= 0:
            reduction_f = ""
        else:
            reduction_f = " (" + str(round((1 - s["filtered"][taskNum]/lastTestedCount_f) * 100)) + '%' + ")"
        lastTestedCount_f = s["filtered"][taskNum];
        
        # print each task row
        print('{:40s} {:15s} {:16s} {:14s}    {:1s}    {:15s} {:16s} {:17s}'.format(s["taskName"][taskNum], str(s["count"][taskNum]) + reduction, str(s["countHoldout"][taskNum]), str(round(zero_div(s["countHoldout"][taskNum], s["count"][taskNum]) * 100,2)) + '%', Fore.CYAN + Style.BRIGHT, str(s["filtered"][taskNum]) + reduction_f, str(s["filteredHoldout"][taskNum]), str(round(zero_div(s["filteredHoldout"][taskNum], s["filtered"][taskNum]) * 100,2)) + '%') + Style.RESET_ALL)
    # print the footer row
    print('')