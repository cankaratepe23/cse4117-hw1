import difflib
import os
import webbrowser

definedinstructions = ["ldi", "inc", "dec", "mov", "mov", "not", "add", "sub", "and", "or", "xor", "ld", "st", "jmp", "jz"]
variables = []

class Variable:
    def __init__(self, name, isarray, valueorsize):
        self.name: str = name
        self.isarray: bool = isarray
        self.valueorsize: int = valueorsize

def testoutput(filename: str, referencefilename: str):
    referencefile = open(referencefilename)
    referencecontent = referencefile.readlines()
    referencefile.close()

    sourcefile = open(filename)
    sourcecontent = sourcefile.readlines()
    sourcefile.close()
    
    htmldiff = difflib.HtmlDiff()
    htmlname = filename + "-diff.html"
    with open(htmlname, "w") as htmlfile:
        htmlfile.writelines(htmldiff.make_file(referencecontent, sourcecontent))
    webbrowser.open("file:///" + os.getcwd() + "/" + htmlname)

def assemble(inputfilename: str, outfilename: str):
    readingdata: bool
    readingcode: bool

    sourcefile = open(inputfilename)
    sourcecontent = sourcefile.readlines()
    sourcefile.close()

    for line in sourcecontent:
        tokenized = line.split()
        if tokenized[0] == ".data":
            readingdata = True
            readingcode = False
            continue
        elif tokenized[0] == ".code":
            readingdata = False
            readingcode = True
            continue
        elif tokenized[0] not in definedinstructions:
            # Reading a label
            pass

        if readingdata:
            varname = tokenized[0][:-1]
            if len(tokenized) == 2:
                # Reading a single variable assignment
                variables.append(Variable(varname, False, int(tokenized[1])))
                pass
            elif len(tokenized) == 3 and tokenized[1] == ".space":
                # Reading a .space variable assignment
                variables.append(Variable(varname, True, int(tokenized[2])))
                pass

            
    

        

assemble("sample1.asm", "sample1.ram")
# testoutput("sample1.ram", "sample1-correct.ram")