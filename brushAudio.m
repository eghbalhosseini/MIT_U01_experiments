function S=brushAudio(wave,Fs,txt,file_id,dataIn)
x=[1:length(wave)]/Fs;
f=figure(1);
clf;
setappdata(f,'new_range',1);
set(f,'position',[-1818 100 1772 600]);


ax1=axes('position',[.01,.1,.98,.7]);
h=plot(x,wave,'k','linewidth',.5);
ax1.YAxis.Visible='off';
ax1.Box='off';
ax1.XAxis.Visible='off';
hold on 
patch_col=inferno(length(fieldnames(dataIn))+2);
    for i=1:length(fieldnames(dataIn))
        
        seg=dataIn.(sprintf('word_%d',i));
        if ~isempty(seg)
        patch([seg(1),seg(2),seg(2),seg(1)],[ax1.YLim(1),ax1.YLim(1),ax1.YLim(2),ax1.YLim(2)],[1,.5,.5],...
            'EdgeColor',[.5,.5,.5],'linewidth',.5,'FaceAlpha',.2,'FaceColor',patch_col(i,:));
        text(mean(seg),ax1.YLim(2),num2str(i),'fontsize',18,'verticalalignment','top');
        end 
    end 
    
txt_split=strsplit(txt);
modif=arrayfun(@(x) sprintf('%d.%s',x,txt_split{x}),1:length(txt_split),'uni',false);
new_txt=strjoin(modif,' | ');
title(sprintf('nonword # %d : %s\n %s',file_id,txt,new_txt),'fontsize',20);
%title(sprintf(' %s',new_txt),'fontsize',20);
soundsc(wave,Fs);
pause(length(wave)/Fs);
B=brush;
pb = uicontrol('style','push',...
    'units','normalized',...
    'Position',[0.45 0.05 0.05 0.05],...
    'fontsize',12,...
    'string','Save',...
    'callback',{@pb_call,dataIn});
set(B,'Enable','on','ActionPostCallback',{@brushedDataCallback,Fs});

%callback function for the pushbutton  (save it in its own *.m file if needed)
end 
function brushedDataCallback(varargin)
hObject=varargin{1};
Fs=varargin{3};
h=findobj(gca,'type','line');
delete(findobj(hObject.Parent,'type','patch',{'tag','candidate'}))
for i=1:size(h)
    idx=get(h(i),'BrushData');
    idx=logical(idx);
    x=get(h(i),'XData');
    x=x(idx);
    y=get(h(i),'YData');
    y=y(idx);
    
end
soundsc(y,Fs);
pause(length(y)/Fs)
%delete(findobj(gca,'type', 'text'))
delete(findobj(hObject.Parent,'type','text',{'tag','candidate_range'}))
section=text(min(x),min(get(gca,'ylim')),sprintf('section : %f to %f',min(x),max(x)),'fontsize',15);
section.Tag='candidate_range';
setappdata(hObject,'new_range',[min(x),max(x)]);
ax=findobj(hObject.Parent,'type','axes');
new_r=[min(x),max(x)];

prop_patch=patch([new_r(1),new_r(2),new_r(2),new_r(1)],[ax.YLim(1),ax.YLim(1),ax.YLim(2),ax.YLim(2)],[.5,.5,1],...
            'EdgeColor','none','FaceAlpha',.3);
prop_patch.Tag='candidate';
end

function pb_call(varargin)
hObject=varargin{1};
data_=varargin{3};
prompt = {'word'};
dlgtitle = 'save section';
dims = [1 35];
definput = {''};
answer = inputdlg(prompt,dlgtitle,dims,definput);
if ~isempty(answer)
new_r = getappdata(hObject.Parent,'new_range');
%assignin('base',strcat('word_',answer{1}),new_r)
evalin('base',sprintf('dataIn.word_%s=[%f,%f]',answer{1},new_r(1),new_r(2)))
ax=findobj(hObject.Parent,'type','axes');
%delete(findobj(hObject.Parent,'type','patch'))

% for i=1:length(fieldnames(data_))
%         seg=data_.(sprintf('word_%d',i));
%         if ~isempty(seg)
%         patch([seg(1),seg(2),seg(2),seg(1)],[ax.YLim(1),ax.YLim(1),ax.YLim(2),ax.YLim(2)],[1,.5,.5],...
%             'EdgeColor','none','FaceAlpha',.3)
%         end 
% end 
   
patch([new_r(1),new_r(2),new_r(2),new_r(1)],[ax.YLim(1),ax.YLim(1),ax.YLim(2),ax.YLim(2)],[1,.5,.5],...
            'EdgeColor','none','FaceAlpha',.3)
end 
        



%section=findobj(gca,'type','text');
%fprintf(section.String)
%set(S.h,'LineStyle','--')
%sprintf('section : %f to %f \n',min(x),max(x))
end
 

