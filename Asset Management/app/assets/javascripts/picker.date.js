(function(a){'function'==typeof define&&define.amd?define(['./picker','jquery'],a):'object'==typeof exports?module.exports=a(require('./picker.js'),require('jquery')):a(Picker,jQuery)})(function(a,b){function c(g,h){var i=this,j=g.$node[0],k=j.value,l=g.$node.data('value'),m=l||k,n=l?h.formatSubmit:h.format,o=function(){return j.currentStyle?'rtl'==j.currentStyle.direction:'rtl'==getComputedStyle(g.$root[0]).direction};i.settings=h,i.$node=g.$node,i.queue={min:'measure create',max:'measure create',now:'now create',select:'parse create validate',highlight:'parse navigate create validate',view:'parse create validate viewset',disable:'deactivate',enable:'activate'},i.item={},i.item.clear=null,i.item.disable=(h.disable||[]).slice(0),i.item.enable=-function(p){return!0===p[0]?p.shift():-1}(i.item.disable),i.set('min',h.min).set('max',h.max).set('now'),m?i.set('select',m,{format:n,defaultValue:!0}):i.set('select',null).set('highlight',i.item.now),i.key={40:7,38:-7,39:function(){return o()?-1:1},37:function(){return o()?1:-1},go:function(p){var q=i.item.highlight,r=new Date(q.year,q.month,q.date+p);i.set('highlight',r,{interval:p}),this.render()}},g.on('render',function(){g.$root.find('.'+h.klass.selectMonth).on('change',function(){var p=this.value;p&&(g.set('highlight',[g.get('view').year,p,g.get('highlight').date]),g.$root.find('.'+h.klass.selectMonth).trigger('focus'))}),g.$root.find('.'+h.klass.selectYear).on('change',function(){var p=this.value;p&&(g.set('highlight',[p,g.get('view').month,g.get('highlight').date]),g.$root.find('.'+h.klass.selectYear).trigger('focus'))})},1).on('open',function(){var p='';i.disabled(i.get('now'))&&(p=':not(.'+h.klass.buttonToday+')'),g.$root.find('button'+p+', select').attr('disabled',!1)},1).on('close',function(){g.$root.find('button, select').attr('disabled',!0)},1)}var d=7,f=a._;c.prototype.set=function(g,h,i){var j=this,k=j.item;return null===h?('clear'==g&&(g='select'),k[g]=h,j):(k['enable'==g?'disable':'flip'==g?'enable':g]=j.queue[g].split(' ').map(function(l){return h=j[l](g,h,i),h}).pop(),'select'==g?j.set('highlight',k.select,i):'highlight'==g?j.set('view',k.highlight,i):g.match(/^(flip|min|max|disable|enable)$/)&&(k.select&&j.disabled(k.select)&&j.set('select',k.select,i),k.highlight&&j.disabled(k.highlight)&&j.set('highlight',k.highlight,i)),j)},c.prototype.get=function(g){return this.item[g]},c.prototype.create=function(g,h,i){var j,k=this;return h=void 0===h?g:h,h==-Infinity||h==Infinity?j=h:b.isPlainObject(h)&&f.isInteger(h.pick)?h=h.obj:b.isArray(h)?(h=new Date(h[0],h[1],h[2]),h=f.isDate(h)?h:k.create().obj):f.isInteger(h)||f.isDate(h)?h=k.normalize(new Date(h),i):h=k.now(g,h,i),{year:j||h.getFullYear(),month:j||h.getMonth(),date:j||h.getDate(),day:j||h.getDay(),obj:j||h,pick:j||h.getTime()}},c.prototype.createRange=function(g,h){var i=this,j=function(k){return!0===k||b.isArray(k)||f.isDate(k)?i.create(k):k};return f.isInteger(g)||(g=j(g)),f.isInteger(h)||(h=j(h)),f.isInteger(g)&&b.isPlainObject(h)?g=[h.year,h.month,h.date+g]:f.isInteger(h)&&b.isPlainObject(g)&&(h=[g.year,g.month,g.date+h]),{from:j(g),to:j(h)}},c.prototype.withinRange=function(g,h){return g=this.createRange(g.from,g.to),h.pick>=g.from.pick&&h.pick<=g.to.pick},c.prototype.overlapRanges=function(g,h){var i=this;return g=i.createRange(g.from,g.to),h=i.createRange(h.from,h.to),i.withinRange(g,h.from)||i.withinRange(g,h.to)||i.withinRange(h,g.from)||i.withinRange(h,g.to)},c.prototype.now=function(g,h,i){return h=new Date,i&&i.rel&&h.setDate(h.getDate()+i.rel),this.normalize(h,i)},c.prototype.navigate=function(g,h,i){var j,k,l,m,n=b.isArray(h),o=b.isPlainObject(h),p=this.item.view;if(n||o){for(o?(k=h.year,l=h.month,m=h.date):(k=+h[0],l=+h[1],m=+h[2]),i&&i.nav&&p&&p.month!==l&&(k=p.year,l=p.month),j=new Date(k,l+(i&&i.nav?i.nav:0),1),k=j.getFullYear(),l=j.getMonth();new Date(k,l,m).getMonth()!==l;)m-=1;h=[k,l,m]}return h},c.prototype.normalize=function(g){return g.setHours(0,0,0,0),g},c.prototype.measure=function(g,h){var i=this;return f.isInteger(h)?h=i.now(g,h,{rel:h}):h?'string'==typeof h&&(h=i.parse(g,h)):h='min'==g?-Infinity:Infinity,h},c.prototype.viewset=function(g,h){return this.create([h.year,h.month,1])},c.prototype.validate=function(g,h,i){var n,o,r,s,j=this,k=h,l=i&&i.interval?i.interval:1,m=-1===j.item.enable,p=j.item.min,q=j.item.max,t=m&&j.item.disable.filter(function(u){if(b.isArray(u)){var v=j.create(u).pick;v<h.pick?n=!0:v>h.pick&&(o=!0)}return f.isInteger(u)}).length;if((!i||!i.nav&&!i.defaultValue)&&(!m&&j.disabled(h)||m&&j.disabled(h)&&(t||n||o)||!m&&(h.pick<=p.pick||h.pick>=q.pick)))for(m&&!t&&(!o&&0<l||!n&&0>l)&&(l*=-1);j.disabled(h)&&(1<Math.abs(l)&&(h.month<k.month||h.month>k.month)&&(h=k,l=0<l?1:-1),h.pick<=p.pick?(r=!0,l=1,h=j.create([p.year,p.month,p.date+(h.pick===p.pick?0:-1)])):h.pick>=q.pick&&(s=!0,l=-1,h=j.create([q.year,q.month,q.date+(h.pick===q.pick?0:1)])),!(r&&s));)h=j.create([h.year,h.month,h.date+l]);return h},c.prototype.disabled=function(g){var h=this,i=h.item.disable.filter(function(j){return f.isInteger(j)?g.day===(h.settings.firstDay?j:j-1)%7:b.isArray(j)||f.isDate(j)?g.pick===h.create(j).pick:b.isPlainObject(j)?h.withinRange(j,g):void 0});return i=i.length&&!i.filter(function(j){return b.isArray(j)&&'inverted'==j[3]||b.isPlainObject(j)&&j.inverted}).length,-1===h.item.enable?!i:i||g.pick<h.item.min.pick||g.pick>h.item.max.pick},c.prototype.parse=function(g,h,i){var j=this,k={};return h&&'string'==typeof h?(i&&i.format||(i=i||{},i.format=j.settings.format),j.formats.toArray(i.format).map(function(l){var m=j.formats[l],n=m?f.trigger(m,j,[h,k]):l.replace(/^!/,'').length;m&&(k[l]=h.substr(0,n)),h=h.substr(n)}),[k.yyyy||k.yy,+(k.mm||k.m)-1,k.dd||k.d]):h},c.prototype.formats=function(){function g(i,j,k){var l=i.match(/[^\x00-\x7F]+|\w+/)[0];return k.mm||k.m||(k.m=j.indexOf(l)+1),l.length}function h(i){return i.match(/\w+/)[0].length}return{d:function(i,j){return i?f.digits(i):j.date},dd:function(i,j){return i?2:f.lead(j.date)},ddd:function(i,j){return i?h(i):this.settings.weekdaysShort[j.day]},dddd:function(i,j){return i?h(i):this.settings.weekdaysFull[j.day]},m:function(i,j){return i?f.digits(i):j.month+1},mm:function(i,j){return i?2:f.lead(j.month+1)},mmm:function(i,j){var k=this.settings.monthsShort;return i?g(i,k,j):k[j.month]},mmmm:function(i,j){var k=this.settings.monthsFull;return i?g(i,k,j):k[j.month]},yy:function(i,j){return i?2:(''+j.year).slice(2)},yyyy:function(i,j){return i?4:j.year},toArray:function(i){return i.split(/(d{1,4}|m{1,4}|y{4}|yy|!.)/g)},toString:function(i,j){var k=this;return k.formats.toArray(i).map(function(l){return f.trigger(k.formats[l],k,[0,j])||l.replace(/^!/,'')}).join('')}}}(),c.prototype.isDateExact=function(g,h){var i=this;return f.isInteger(g)&&f.isInteger(h)||'boolean'==typeof g&&'boolean'==typeof h?g===h:(f.isDate(g)||b.isArray(g))&&(f.isDate(h)||b.isArray(h))?i.create(g).pick===i.create(h).pick:b.isPlainObject(g)&&b.isPlainObject(h)&&i.isDateExact(g.from,h.from)&&i.isDateExact(g.to,h.to)},c.prototype.isDateOverlap=function(g,h){var i=this,j=i.settings.firstDay?1:0;return f.isInteger(g)&&(f.isDate(h)||b.isArray(h))?(g=g%7+j,g===i.create(h).day+1):f.isInteger(h)&&(f.isDate(g)||b.isArray(g))?(h=h%7+j,h===i.create(g).day+1):b.isPlainObject(g)&&b.isPlainObject(h)&&i.overlapRanges(g,h)},c.prototype.flipEnable=function(g){var h=this.item;h.enable=g||(-1==h.enable?1:-1)},c.prototype.deactivate=function(g,h){var i=this,j=i.item.disable.slice(0);return'flip'==h?i.flipEnable():!1===h?(i.flipEnable(1),j=[]):!0===h?(i.flipEnable(-1),j=[]):h.map(function(k){for(var l,m=0;m<j.length;m+=1)if(i.isDateExact(k,j[m])){l=!0;break}!l&&(f.isInteger(k)||f.isDate(k)||b.isArray(k)||b.isPlainObject(k)&&k.from&&k.to)&&j.push(k)}),j},c.prototype.activate=function(g,h){var i=this,j=i.item.disable,k=j.length;return'flip'==h?i.flipEnable():!0===h?(i.flipEnable(1),j=[]):!1===h?(i.flipEnable(-1),j=[]):h.map(function(l){var m,n,o,p;for(o=0;o<k;o+=1)if(n=j[o],i.isDateExact(n,l)){m=j[o]=null,p=!0;break}else if(i.isDateOverlap(n,l)){b.isPlainObject(l)?(l.inverted=!0,m=l):b.isArray(l)?(m=l,!m[3]&&m.push('inverted')):f.isDate(l)&&(m=[l.getFullYear(),l.getMonth(),l.getDate(),'inverted']);break}if(m)for(o=0;o<k;o+=1)if(i.isDateExact(j[o],l)){j[o]=null;break}if(p)for(o=0;o<k;o+=1)if(i.isDateOverlap(j[o],l)){j[o]=null;break}m&&j.push(m)}),j.filter(function(l){return null!=l})},c.prototype.nodes=function(g){var h=this,i=h.settings,j=h.item,k=j.now,l=j.select,m=j.highlight,n=j.view,o=j.disable,p=j.min,q=j.max,r=function(v,w){return i.firstDay&&(v.push(v.shift()),w.push(w.shift())),f.node('thead',f.node('tr',f.group({min:0,max:d-1,i:1,node:'th',item:function(x){return[v[x],i.klass.weekdays,'scope=col title="'+w[x]+'"']}})))}((i.showWeekdaysFull?i.weekdaysFull:i.weekdaysShort).slice(0),i.weekdaysFull.slice(0)),s=function(v){return f.node('div',' ',i.klass['nav'+(v?'Next':'Prev')]+(v&&n.year>=q.year&&n.month>=q.month||!v&&n.year<=p.year&&n.month<=p.month?' '+i.klass.navDisabled:''),'data-nav='+(v||-1)+' '+f.ariaAttr({role:'button',controls:h.$node[0].id+'_table'})+' title="'+(v?i.labelMonthNext:i.labelMonthPrev)+'"')},t=function(){var v=i.showMonthsShort?i.monthsShort:i.monthsFull;return i.selectMonths?f.node('select',f.group({min:0,max:11,i:1,node:'option',item:function(w){return[v[w],0,'value='+w+(n.month==w?' selected':'')+(n.year==p.year&&w<p.month||n.year==q.year&&w>q.month?' disabled':'')]}}),i.klass.selectMonth,(g?'':'disabled')+' '+f.ariaAttr({controls:h.$node[0].id+'_table'})+' title="'+i.labelMonthSelect+'"'):f.node('div',v[n.month],i.klass.month)},u=function(){var v=n.year,w=!0===i.selectYears?5:~~(i.selectYears/2);if(w){var x=p.year,y=q.year,z=v-w,A=v+w;if(x>z&&(A+=x-z,z=x),y<A){var B=z-x,C=A-y;z-=B>C?C:B,A=y}return f.node('select',f.group({min:z,max:A,i:1,node:'option',item:function(D){return[D,0,'value='+D+(v==D?' selected':'')]}}),i.klass.selectYear,(g?'':'disabled')+' '+f.ariaAttr({controls:h.$node[0].id+'_table'})+' title="'+i.labelYearSelect+'"')}return f.node('div',v,i.klass.year)};return f.node('div',(i.selectYears?u()+t():t()+u())+s()+s(1),i.klass.header)+f.node('table',r+f.node('tbody',f.group({min:0,max:6-1,i:1,node:'tr',item:function(v){var w=i.firstDay&&0===h.create([n.year,n.month,1]).day?-7:0;return[f.group({min:d*v-n.day+w+1,max:function(){return this.min+d-1},i:1,node:'td',item:function(x){x=h.create([n.year,n.month,x+(i.firstDay?1:0)]);var y=l&&l.pick==x.pick,z=m&&m.pick==x.pick,A=o&&h.disabled(x)||x.pick<p.pick||x.pick>q.pick,B=f.trigger(h.formats.toString,h,[i.format,x]);return[f.node('div',x.date,function(C){return C.push(n.month==x.month?i.klass.infocus:i.klass.outfocus),k.pick==x.pick&&C.push(i.klass.now),y&&C.push(i.klass.selected),z&&C.push(i.klass.highlighted),A&&C.push(i.klass.disabled),C.join(' ')}([i.klass.day]),'data-pick='+x.pick+' '+f.ariaAttr({role:'gridcell',label:B,selected:y&&h.$node.val()===B||null,activedescendant:!!z||null,disabled:!!A||null})),'',f.ariaAttr({role:'presentation'})]}})]}})),i.klass.table,'id="'+h.$node[0].id+'_table" '+f.ariaAttr({role:'grid',controls:h.$node[0].id,readonly:!0}))+f.node('div',f.node('button',i.today,i.klass.buttonToday,'type=button data-pick='+k.pick+(g&&!h.disabled(k)?'':' disabled')+' '+f.ariaAttr({controls:h.$node[0].id}))+f.node('button',i.clear,i.klass.buttonClear,'type=button data-clear=1'+(g?'':' disabled')+' '+f.ariaAttr({controls:h.$node[0].id}))+f.node('button',i.close,i.klass.buttonClose,'type=button data-close=true '+(g?'':' disabled')+' '+f.ariaAttr({controls:h.$node[0].id})),i.klass.footer)},c.defaults=function(g){return{labelMonthNext:'Next month',labelMonthPrev:'Previous month',labelMonthSelect:'Select a month',labelYearSelect:'Select a year',monthsFull:['January','February','March','April','May','June','July','August','September','October','November','December'],monthsShort:['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],weekdaysFull:['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],weekdaysShort:['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],today:'Today',clear:'Clear',close:'Close',closeOnSelect:!0,closeOnClear:!0,format:'d mmmm, yyyy',klass:{table:g+'table',header:g+'header',navPrev:g+'nav--prev',navNext:g+'nav--next',navDisabled:g+'nav--disabled',month:g+'month',year:g+'year',selectMonth:g+'select--month',selectYear:g+'select--year',weekdays:g+'weekday',day:g+'day',disabled:g+'day--disabled',selected:g+'day--selected',highlighted:g+'day--highlighted',now:g+'day--today',infocus:g+'day--infocus',outfocus:g+'day--outfocus',footer:g+'footer',buttonClear:g+'button--clear',buttonToday:g+'button--today',buttonClose:g+'button--close'}}}(a.klasses().picker+'__'),a.extend('pickadate',c)});