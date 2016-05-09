str= "sm update incident IM10229 a.d=abc ed=‘adaasd “dasf’ aer=“adsf ‘ sdfas=\""
str = str.replace  /[\u201C|\u201D]/g, '"'
str = str.replace /[\u2019|\u2018]/g, "'"
console.log str
reg = /sm\s+update\s+incident\s+([\d\w]+)\s+(.*)/i

m = reg.exec(str);
# console.log m

Qs =
  '\'':'\''
  '"':'"'


params = m[2]
r = /([\w\d\.]+)=(?:(?:'([^']+)')|(?:"([^"]+)")|(\S+))/gi
m = r.exec params
while(m)
  # console.log m
  value = m[2] or m[3] or m[4]
  console.log "#{m[1]}=#{value}"
  m = r.exec params


# console.log m, r.lastIndex
