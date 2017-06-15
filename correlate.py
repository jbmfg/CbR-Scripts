import csv, json, re, urllib.parse
from collections import defaultdict

class correlate(object):
    cutoff_val = 500       #   change this to whatever you want your watchlist runtime to be
    
    def __init__(self, qtime, watchlists):
        self.qtime = qtime
        self.watchlists = watchlists
        
    def readWL(self):       
        '''Read watchlist csv and pull what we want out'''
        wlDict = {}
        with open(self.watchlists, 'r', encoding='utf8') as f:
            readFile = csv.reader(f)
            for x in list(readFile):
                wlDict["watchlist_" + str(x[0])]=[x[2],urllib.parse.unquote(x[4])]
            f.close()
        return wlDict

    def readqtime(self):    
        '''Read qtime txt and pull what we want out'''
        qtimeDict = defaultdict(list)
        with open(self.qtime, 'r', encoding='utf8') as f:
            tempOut = f.read()
            tempOut = urllib.parse.unquote(tempOut)
            ptrn = re.compile(r"^([0-9]+).+(watchlist_[0-9]+).+$",re.MULTILINE)
            idAndTimes = re.finditer(ptrn, tempOut)
            for m in idAndTimes:
                if int(m.group(1))>= self.cutoff_val:
                    qtimeDict[m.group(2)].append(int(m.group(1)))
                else:
                    pass
        f.close()
        return qtimeDict
        
        
    def maths(self, qtimeDict):
        '''build a dictionary with the calculations'''
        results = {}
        for k,v in qtimeDict.items():
            results[k] = {"min":v[-1], "max":v[0], "avg":(sum(v))/len(v), "count":len(v)}
        return results
            
            
    def writeCsv(self, results, wlDict):
        '''Output to CSV file'''
        f = csv.writer(open("SlowestWatchlists.csv", "w", newline=''))
        f.writerow(["Watchlist ID", "Name", "Min", "Max", "Avg", "Count", "URL Param"])
        for k in results:
            try:
                f.writerow([k, wlDict[k][0], results[k]["min"], results[k]["max"], results[k]["avg"], results[k]["count"], wlDict[k][1]])
            except: 
                pass #I dont care about errors ;)
        return True
            
        



def main():
    correlation = correlate('qtime.txt', 'watchlists.csv')
    parsedQTime = correlation.readqtime()
    wlDict = correlation.readWL()
    doMath = correlation.maths(parsedQTime)
    export = correlation.writeCsv(doMath, wlDict)
    json.dump(parsedQTime, open('allresults.json', 'w'))



if __name__ == '__main__':
    main()

