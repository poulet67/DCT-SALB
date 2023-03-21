import re

f = open("codenames.txt", "r", encoding='utf-8')

cns = f.read()

f.close()

cn_ls = re.findall("\n[A-Z]+", cns) #all words after a newline (destroys two word callsigns)

cn_ls = dict.fromkeys(cn_ls) 
cn_ls = list(cn_ls) #remove duplicates
mystring = ''.join(cn_ls)

f = open("Output.txt", "w", encoding='utf-8')

f.write(mystring)
f.close()