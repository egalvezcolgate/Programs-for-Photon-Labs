%% Data Acquisition from Altera DE2 board through Serial port
% Free-running with 4 detectors
% Original Version Behzad Khajavi and Baibhav Sharma 5/2018
% Revision Kiko Galvez 3/2022
% Revision including a translation stage scan 3/16/33 2:58 pm KG
% Revision for long and short times down to 0.1 s 3/276/22 KG
% Modified for clearing input buffers 5/29/22 KG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% The goal is to take data from Altera DE2 board through a serial port.   %
% ALTERA sends out 8 numbers that are 32-bit numbers. They correspond to 8%
% counters which are A, B, A' and B' singles as well as AB, A'B, AB' and  %
% A'B' coincidences respectively.                                         %
%_________________________________________________________________________%
%                                                                         %
%*************************************************************************%
%_________________________________________________________________________%
%                                                                         %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear;
close all;
format compact
% defining object s for serial instrument. BaudRate=19200 bps, DataBits=8
% StopBits=1, Parity=none.
% The COM port is determined by the Device Manager in Windows.
% Motor mover HOM section
%
prompt = {'Enter the COM# of the Counter:','Enter the COM# of Stage:','Start Position','End Position','P Increment','time interval','Excel file name','Coincidence Time (ns)'};
dlg_title = 'Translation Scan 4 detectors';
defaultans = {'COM21','COM12','0','400','10','1','Transl','40'};%[1 length(dlg_title)+10],[1 5;1 5;1 5;1 30]
%defaultans = {'COM10','COM8','-720','720','18','2','HOM113'};%[1 length(dlg_title)+10],[1 5;1 5;1 5;1 30]
% 1 = 1.33 um
userinput = inputdlg(prompt,dlg_title,[1 length(dlg_title)+30],defaultans);
counterportnum = userinput{1}; % # of states to do the tomography for
PacificPortNum = userinput{2}; % COM# for the Arduino
% Properties for Arduino and Piezo Voltage
Mstart = str2double(userinput{3});
Mend = str2double(userinput{4});
Minc = str2double(userinput{5});
Tcoincstr=userinput{8};
Tcoinc = str2double(Tcoincstr);
Mrange=Mend-Mstart;
numofsteps = round((Mend - Mstart)/Minc,0); %defines the number of measurements
timeinterval = str2double(userinput{6}); % time interval for each measurement in seconds
%
%
% prompt = {'Enter the COM# of the Counter:','number of intervals','time per interval','Name of file = '};
% dlg_title = 'Four-detector Dialog';
% defaultans = {'COM6','5','1','Four'};%[1 length(dlg_title)+10],[1 5;1 5;1 5;1 30]
% userinput = inputdlg(prompt,dlg_title,[1 length(dlg_title)+30],defaultans);
% counterportnum = userinput{1};
numofmeasurements= numofsteps+1;
% timeinterval = str2double(userinput{3}); % time interval for each measurement in seconds
%nams = userinput{3};
nams = userinput{7};
datanam = strcat(nams,'.xlsx');  %'TM11805Normal3632'; % data name
%prompt = 'Counter COM port #: ';
%dlg_title = 'Counter COM port';
%default = {'COM6'};
%counterportnum = inputdlg(prompt,dlg_title,[1 length(dlg_title)+30],default);
scounter = serial(counterportnum,'BaudRate',19200,'DataBits',8,'StopBits',1,'Parity','none');
sPacific = serialport(PacificPortNum,9600);
configureTerminator(sPacific,'CR')


%% Loop

numofstates = 1; % # of states to do the tomography for
%numofmeasurements = 10; % # of measurements per each state
%timeinterval = 1; % time interval for each measurement in seconds
loop = numofmeasurements;
deltat = Tcoinc*1e-9; % pulse width to calculate accidental coincidences
count=1; pausetime=0; time=zeros(loop);statepause=0;
clockt=fix(clock); % saving the initial date/time into a matrix
% myDatadimension=41*(timeinterval*10)+40; % timeinterval*10=timeinterval in seconds
% cleandatadimension=41*(timeinterval*10);
% myData=zeros(myDatadimension,1);
% resultsmatrix=zeros(numofmeasurements,8);
% erasingmatrix(1:(numofmeasurements+1)*numofstates+3,1:8)="";% matrix defined to erase the excel sheet
Sheet1=strcat('Data points',num2str(clockt(1,4:6)));
%Sheet2=strcat('Average results',num2str(clockt(1,4:6)));
% xlswrite('resultsmatrix.xlsx',erasingmatrix,Sheet1,'A1')%erasing sheet 1
% xlswrite('resultsmatrix.xlsx',erasingmatrix,Sheet2,'A1')%erasing sheet 2
% Start the excel file to write the gradual results
xlrange1='A1';

warning('off','MATLAB:xlswrite:AddSheet');
% to suppress the warning when the sheet name is not in excel file.
%Header1={'A','B','AB','Accidenals'};
%Header1={'Position','A','B','A`','B`','AB','AA`','BB`','A`B`','Acc-AB','Acc-AA`','Acc-BB`','Acc-A`B`'};
Header1={'Position','A','B','A`','B`','AB','BA`','AB`','A`B`','Acc-AB','Acc-BA`','Acc-AB`','Acc-A`B`'};
xlswrite(nams,Header1,Sheet1,xlrange1)
% End of writing the header for the "Gradual Results" sheet in excel file.

% Start the excel file to write the "Total Results" sheet

warning('off','MATLAB:xlswrite:AddSheet');
% to suppress the warning when the sheet name is not in excel file.
%Header2={'Position','A','B','A`','B`','AB','AA`','BB`','A`B`','Acc-AB','Acc-AA`','Acc-BB`','Acc-A`B`'};
%xl2range1='A1';
%xlswrite(nams,Header2,Sheet2,xl2range1)
% End of writing the header for the "Gradual Results" sheet in excel file.

for stateindexi=1:numofstates
    % header for each state measurement results in excel file "Gradual Results"
    countt=num2str((stateindexi-1)*(numofmeasurements)+2);% to go two lines further (count+1)in excel (because of the header)
    xlrange2=strcat('A',countt);
    stateindexit=num2str(stateindexi);
    stateheader={'state #',stateindexit};
    xlswrite(nams,stateheader,Sheet1,xlrange2);
    % header for each state measurement results in excel file "Total Results"
    %countt=num2str((stateindexi-1)*2+2);
    %xl2range2=strcat('A',countt);
    %xlswrite(nams,stateheader,Sheet2,xl2range2);

    %% Figure adjustments
    screensize = get( groot, 'Screensize' ); %getting screen size
    position=[1 screensize(1,4)/2-100 screensize(1,3) screensize(1,4)/2];
    f1=figure('Name','4 Detector Data Acquisition','numbertitle','off','Position',screensize,'color',[0.7 0.7 0.7]);
    %_____________________________________
    % Axes Properties
    % axes('position',[left bottom width height])

    % Axis for Header
    axheader=axes('position',[0.45 0.88 0.1 0.05],'visible','off');
    axheader.Title.Visible = 'on';
    set(get(gca,'title'),'color','w','background','b')% figure header text:white, background:blue
    %
    %_____________________________________
    % Coincidence Time window
    axCoinc=axes('position',[0.8 0.88 0.1 0.05],'visible','off');
    axCoinc.Title.Visible = 'on';
    descrCoinc = ['Coinc. Time = ',Tcoincstr,' ns'];
    title(axCoinc,descrCoinc,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
    set(get(gca,'title'),'color','w','background','b')
    %_____________________________________
    % Accidental windows
    axAB=axes('position',[0.08 0.03 0.1 0.05],'visible','off');
    axAB.Title.Visible = 'on';
    set(get(gca,'title'),'color','w','background','b')% figure header text:white, background:blue
%     axAAp=axes('position',[0.33 0.03 0.1 0.05],'visible','off');
%     axAAp.Title.Visible = 'on';
    axBAp=axes('position',[0.33 0.03 0.1 0.05],'visible','off');
    axBAp.Title.Visible = 'on';
    set(get(gca,'title'),'color','w','background','b')% figure header text:white, background:blue
%     axBBp=axes('position',[0.58 0.03 0.1 0.05],'visible','off');
%     axBBp.Title.Visible = 'on';
    axABp=axes('position',[0.58 0.03 0.1 0.05],'visible','off');
    axABp.Title.Visible = 'on';
    set(get(gca,'title'),'color','w','background','b')% figure header text:white, background:blue
    axApBp=axes('position',[0.83 0.03 0.1 0.05],'visible','off');
    axApBp.Title.Visible = 'on';
    set(get(gca,'title'),'color','w','background','b')% figure header text:white, background:blue
    %_____________________________________
    % Axes for plots
    plotwidth = 0.20;
    plotheight = 0.25;
    ax1 = axes('position',[0.04 0.6 plotwidth plotheight]); % Axies 1 position in the figure
    set(get(ax1,'title'),'color','w','background','b')
    ax1.YLim = [0 inf];
    %ax1.XLim = [0 numofmeasurements+1]; old
    ax1.XLim = [Mstart Mend];
    set(ax1,'XTick',Mstart:Mrange/5:Mend)
    ax1.XLabel.String  = 'Motor Position';ax1.XLabel.FontWeight = 'bold';
    ax1.YLabel.String  = 'Singles A';ax1.YLabel.FontWeight = 'bold';
    ax1.XLabel.FontSize = 10;ax2.XLabel.FontName = 'TimesNewRoman';
    %set(ax1,'XTick',0:loop/10:loop*timeinterval+1) old
    %ax1.YLabel.String  = 'A';ax1.YLabel.FontWeight = 'bold';
    ax1.YLabel.FontSize = 15;ax1.YLabel.FontName = 'TimesNewRoman';
    grid(ax1,'on');
    hold(ax1,'on')
    %____________________________________

    ax2 = axes('position',[0.29 0.6 plotwidth plotheight]); % Axies 2 position in the figure
    set(get(ax2,'title'),'color','w','background','b')
    ax2.XLim = [Mstart Mend];
    set(ax2,'XTick',Mstart:Mrange/5:Mend)
    ax2.XLabel.String  = 'Motor Position';ax2.XLabel.FontWeight = 'bold';
    ax2.YLabel.String  = 'Singles B';ax2.YLabel.FontWeight = 'bold';
    ax2.YLim = [0 inf];
    ax2.XLabel.FontSize = 10;ax2.XLabel.FontName = 'TimesNewRoman';
    ax2.YLabel.FontSize = 15;ax2.YLabel.FontName = 'TimesNewRoman';
    grid(ax2,'on');
    hold(ax2,'on')
    %__________________________________________________________________
    ax3 = axes('position',[0.54 0.6 plotwidth plotheight]); % Axies 3 position in the figure
    set(get(ax3,'title'),'color','w','background','b')
    ax3.XLim = [Mstart Mend];
    set(ax3,'XTick',Mstart:Mrange/5:Mend)
    ax3.XLabel.String  = 'Motor Position';ax3.XLabel.FontWeight = 'bold';
    ax3.YLabel.String  = 'Singles A`';ax3.YLabel.FontWeight = 'bold';
    ax3.YLim = [0 inf];
    ax3.XLabel.FontSize = 10;ax3.XLabel.FontName = 'TimesNewRoman'; %time font
    ax3.YLabel.FontSize = 15;ax3.YLabel.FontName = 'TimesNewRoman';
    grid(ax3,'on');
    hold(ax3,'on')
    %____________________________________

    ax4 = axes('position',[0.79 0.6 plotwidth plotheight]); % Bob (d) position in the figure
    set(get(ax4,'title'),'color','w','background','b')
    ax4.XLim = [Mstart Mend];
    set(ax4,'XTick',Mstart:Mrange/5:Mend)
    ax4.XLabel.String  = 'Motor Position';ax4.XLabel.FontWeight = 'bold';
    ax4.YLabel.String  = 'Singles B`';ax4.YLabel.FontWeight = 'bold';
    ax4.YLim = [0 inf];
    ax4.XLabel.FontSize = 10;ax4.XLabel.FontName = 'TimesNewRoman';
    ax4.YLabel.FontSize = 15;ax4.YLabel.FontName = 'TimesNewRoman';
    grid(ax4,'on');
    hold(ax4,'on')

    %___________________________________________________________________
    ax5=axes('position',[0.04 0.2 plotwidth plotheight]); % Axies 5 position in the figure
    set(get(ax5,'title'),'color','w','background','b')
    ax5.XLim = [Mstart Mend];
    set(ax5,'XTick',Mstart:Mrange/5:Mend)
    ax5.XLabel.String  = 'Motor Position';ax5.XLabel.FontWeight = 'bold';
    ax5.YLabel.String  = 'Doubles AB';ax5.YLabel.FontWeight = 'bold';
    ax5.YLim = [0 inf];
    ax5.XLabel.FontSize = 10;ax5.XLabel.FontName = 'TimesNewRoman';
    ax5.YLabel.FontSize = 15;ax5.YLabel.FontName = 'TimesNewRoman';
    grid(ax5,'on');
    hold(ax5,'on')
    %______________________________________________________________
    ax6=axes('position',[0.29 0.2 plotwidth plotheight]); % Axies 6 position in the figure
    set(get(ax6,'title'),'color','w','background','b')
    ax6.XLim = [Mstart Mend];
    set(ax6,'XTick',Mstart:Mrange/5:Mend)
    ax6.XLabel.String  = 'Motor Position';ax6.XLabel.FontWeight = 'bold';
%    ax6.YLabel.String  = 'Doubles AA`';ax6.YLabel.FontWeight = 'bold';
    ax6.YLabel.String  = 'Doubles BA`';ax6.YLabel.FontWeight = 'bold';
    ax6.YLim = [0 inf];
    ax6.XLabel.FontSize = 10;ax6.XLabel.FontName = 'TimesNewRoman';
    ax6.YLabel.FontSize = 15;ax6.YLabel.FontName = 'TimesNewRoman';
    grid(ax6,'on');
    hold(ax6,'on')
    %_________________________________________________________________
    ax7=axes('position',[0.54 0.2 plotwidth plotheight]); % Axies 7 position in the figure
    set(get(ax7,'title'),'color','w','background','b')
    ax7.XLim = [Mstart Mend];
    set(ax7,'XTick',Mstart:Mrange/5:Mend)
    ax7.XLabel.String  = 'Motor Position';ax7.XLabel.FontWeight = 'bold';
%     ax7.YLabel.String  = 'Doubles BB`';ax7.YLabel.FontWeight = 'bold';
    ax7.YLabel.String  = 'Doubles AB`';ax7.YLabel.FontWeight = 'bold';
    ax7.YLim = [0 inf];
    ax7.XLabel.FontSize = 10;ax7.XLabel.FontName = 'TimesNewRoman';
    ax7.YLabel.FontSize = 15;ax7.YLabel.FontName = 'TimesNewRoman';
    grid(ax7,'on');
    hold(ax7,'on')

    %____________________________________________________________________
    ax8=axes('position',[0.79 0.2 plotwidth plotheight]); % Axies 8 position in the figure
    set(get(ax8,'title'),'color','w','background','b')
    ax8.XLim = [Mstart Mend];
    set(ax8,'XTick',Mstart:Mrange/5:Mend)
    ax8.XLabel.String  = 'Motor Position';ax8.XLabel.FontWeight = 'bold';
    ax8.YLabel.String  = 'Doubles A`B`';ax8.YLabel.FontWeight = 'bold';
    ax8.YLim = [0 inf];
    ax8.XLabel.FontSize = 10;ax8.XLabel.FontName = 'TimesNewRoman';
    ax8.YLabel.FontSize = 15;ax8.YLabel.FontName = 'TimesNewRoman';
    grid(ax8,'on');
    hold(ax8,'on')
    %____________________________________________________________________

    %% The Loop
    fopen(scounter);  % open the serial port before the inner loop begins.
    %****************************************************************************

    while ~isequal(count,loop+1)
       numofcounts=zeros(1,8);
       Mcurr=Mstart + (count-1)*Minc;
        StepToPacific = strcat('MA',num2str(Mcurr));
        %    fprintf(sPacific,StepToPacific);
        writeline(sPacific,StepToPacific);
        pause(1)
%%%%%%%%%%%%%%%%%% Long times
        if timeinterval > 10
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes
            pause(1);
            flushinput(scounter);
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes            
            flushinput(scounter);
            times10loop=floor(timeinterval/10);
            for il=1:times10loop
                if il == times10loop
                    time10=10+rem(timeinterval,10);
                else
                    time10=10;
                end
                myDatadimension=41*(time10*10)+40; % timeinterval*10=timeinterval in seconds
                cleandatadimension=41*(time10*10);
                myData=zeros(1,myDatadimension);
                for i=1:time10
                    myData1 = fread(scounter,512,'uint8'); % reading # of bytes
                    myData(1,(i-1)*512+1:i*512) = myData1';
                end
                % finding terminationbyte if the 41th element of myData is not 255
                tbi=0;
                if myData(1,41)~=255
                    for i=1:40
                        if myData(1,i)==255
                            terminationbyteindex=i;
                        end
                    end
                    tbi=terminationbyteindex;
                end
                % saving myData portion into cleandata so the array starts with A
                % that is right after the first termination byte (255)

                cleandata=myData(1,tbi+1:tbi+cleandatadimension);
                %            numofcounts=zeros(1,8);
                CD=cleandata; % just to use a shorthand notation CD
                kmax=time10*10; % loop repetition number for each counter
                L=0;j=0;
                for i=1:8
                    j=0;
                    for k=1:kmax
                        numofcounts(1,i)=numofcounts(1,i)+CD(1,1+j+L)+2^7*CD(1,2+j+L)+2^14*CD(1,3+j+L)+2^21*CD(1,4+j+L)+2^28*CD(1,5+j+L);
                        j=j+41; % the corresponding figure after a tenth of a second
                    end
                    L=L+5; % next counter partition starts at the next 5th byte
                end
            end
        elseif timeinterval<1
 %%%%%%%%%%%%%%%%   Short times
            myDatadimension=41*10+40; % timeinterval*10=timeinterval in seconds
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes
%            pause(1);
            flushinput(scounter);
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes            
            flushinput(scounter);
            cleandatadimension=41*10;
            myData=zeros(1,myDatadimension);
            %        for i=1:timeinterval
            myData1 = fread(scounter,512,'uint8'); % reading # of bytes
            myData(1,1:512) = myData1';
            %            myData(1,(i-1)*512+1:i*512) = myData1';
            %        end
            % finding terminationbyte if the 41th element of myData is not 255
            tbi=0;
            if myData(1,41)~=255
                for i=1:40
                    if myData(1,i)==255
                        terminationbyteindex=i;
                    end
                end
                tbi=terminationbyteindex;
            end
            % saving myData portion into cleandata so the array starts with A
            % that is right after the first termination byte (255)

            cleandata=myData(1,tbi+1:tbi+cleandatadimension);
            %        numofcounts=zeros(1,8);
            CD=cleandata; % just to use a shorthand notation CD
            kmax=timeinterval*10; % loop repetation numner for each counter
            L=0;j=0;
            for i=1:8
                j=0;
                for k=1:kmax
                    numofcounts(1,i)=numofcounts(1,i)+CD(1,1+j+L)+2^7*CD(1,2+j+L)+2^14*CD(1,3+j+L)+2^21*CD(1,4+j+L)+2^28*CD(1,5+j+L);
                    j=j+41; % the corresponding figure after a tenth of a second
                end
                L=L+5; % next counter partition starts at the next 5th byte
            end
        else
            %%%%%%%%%%%%%%%%%%   Regular times
            myDatadimension=41*(timeinterval*10)+40; % timeinterval*10=timeinterval in seconds
            cleandatadimension=41*(timeinterval*10);
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes
            pause(1);
            flushinput(scounter);
            myData0 = fread(scounter,512,'uint8'); % reading # of bytes            
            flushinput(scounter);
%            myData=zeros(myDatadimension,1);
            myData=zeros(1,myDatadimension);
            for i=1:timeinterval
                myData1 = fread(scounter,512,'uint8'); % reading # of bytes
                myData(1,(i-1)*512+1:i*512) = myData1';
            end
            % finding terminationbyte if the 41th element of myData is not 255
            tbi=0;
            if myData(1,41)~=255
                for i=1:40
                    if myData(1,i)==255
                        terminationbyteindex=i;
                    end
                end
                tbi=terminationbyteindex;
            end
            % saving myData portion into cleandata so the array starts with A
            % that is right after the first termination byte (255)

            cleandata=myData(1,tbi+1:tbi+cleandatadimension);
            numofcounts=zeros(1,8);
            CD=cleandata; % just to use a shorthand notation CD
            kmax=timeinterval*10; % loop repetation numner for each counter
            L=0;j=0;
            for i=1:8
                j=0;
                for k=1:kmax
                    numofcounts(1,i)=numofcounts(1,i)+CD(1,1+j+L)+2^7*CD(1,2+j+L)+2^14*CD(1,3+j+L)+2^21*CD(1,4+j+L)+2^28*CD(1,5+j+L);
                    j=j+41; % the corresponding figure after a tenth of a second
                end
                L=L+5; % next counter partition starts at the next 5th byte
            end
        end
        %%%%%%%%%%%%%%%%%%%%% end of taking data        % Serial data accessing
%         for i=1:timeinterval
%             myData1 = fread(scounter,512,'uint8'); % reading # of bytes
%             myData(1,(i-1)*512+1:i*512) = myData1';
%         end
%         % finding terminationbyte if the 41th element of myData is not 255
%         tbi=0;
%         if myData(1,41)~=255
%             for i=1:40
%                 if myData(1,i)==255
%                     terminationbyteindex=i;
%                 end
%             end
%             tbi=terminationbyteindex;
%         end
%         % saving myData portion into cleandata so the array starts with A
%         % that is right after the first termination byte (255)
% 
%         cleandata=myData(1,tbi+1:tbi+cleandatadimension);
%         numofcounts=zeros(1,8);
%         CD=cleandata; % just to use a shorthand notation CD
%         kmax=timeinterval*10; % loop repetation numner for each counter
%         L=0;j=0;
%         for i=1:8
%             j=0;
%             for k=1:kmax
%                 numofcounts(1,i)=numofcounts(1,i)+CD(1,1+j+L)+2^7*CD(1,2+j+L)+2^14*CD(1,3+j+L)+2^21*CD(1,4+j+L)+2^28*CD(1,5+j+L);
%                 j=j+41; % the corresponding figure after a tenth of a second
%             end
%             L=L+5; % next counter partition starts at the next 5th byte
%        end
        numofcountsA=numofcounts(1,1);
        numofcountsB=numofcounts(1,2);
        numofcountsAprime=numofcounts(1,3);
        numofcountsBprime=numofcounts(1,4);
        numofcountsAB=numofcounts(1,5);
%         numofcountsAprimeA=numofcounts(1,6);
        numofcountsBAprime=numofcounts(1,6);
%         numofcountsBBprime=numofcounts(1,7);
        numofcountsABprime=numofcounts(1,7);
        numofcountsAprimeBprime=numofcounts(1,8);

        %% Plotting the data points on different subplots
        % Drawing Y-data of the 8 plots (A, A', B, B', AA', BB', A'B', AB) at the same time
        time(count) = count*timeinterval; % x-axis (time) in seconds
        % plotting A
        plot(ax1,Mcurr,numofcounts(1,1),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting A'
        plot(ax3,Mcurr,numofcounts(1,3),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting B
        plot(ax2,Mcurr,numofcounts(1,2),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting B'
        plot(ax4,Mcurr,numofcounts(1,4),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting AB
        plot(ax5,Mcurr,numofcounts(1,5),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting BB' (AAd) NEW: AB'
        plot(ax7,Mcurr,numofcounts(1,7),'. b','Markersize',20)
        %----------------------------------------------------------------------
        % plotting A'B'
        plot(ax8,Mcurr,numofcounts(1,8),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % plotting AA' NEW: BA'
        plot(ax6,Mcurr,numofcounts(1,6),'. b','MarkerSize',20)
        %----------------------------------------------------------------------
        % Showing the numbers (counts) in the title of the axes 1-8
        descriptionBd = num2str(numofcounts(1,1));
        fontsize = 25;
        title(ax1,descriptionBd,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

        descriptionB = num2str(numofcounts(1,2));
        title(ax2,descriptionB,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

        descriptionA = num2str(numofcounts(1,3));
        title(ax3,descriptionA,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

        descriptionAd = num2str(numofcounts(1,4));
        title(ax4,descriptionAd,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

        descriptionAB = num2str(numofcounts(1,5));
        title(ax5,descriptionAB,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

%         descriptionAAprime = num2str(numofcounts(1,6));
%         title(ax6,descriptionAAprime,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');
        descriptionBAprime = num2str(numofcounts(1,6));
        title(ax6,descriptionBAprime,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');


%         descriptionBBprime = num2str(numofcounts(1,7));
%         title(ax7,descriptionBBprime,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');
        descriptionABprime = num2str(numofcounts(1,7));
        title(ax7,descriptionABprime,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');

        descriptionAprimeBprime = num2str(numofcounts(1,8));
        title(ax8,descriptionAprimeBprime,'FontWeight','bold','FontSize',fontsize,'FontName','Times New Roman');


        %    descr = ['QKD Data Acquisition: ','State # ',num2str(stateindexi),'/',num2str(numofstates),', measurement #',num2str(count),'/',num2str(numofmeasurements)];
        descr = ['Measurement: ',num2str(count),'/',num2str(numofmeasurements)];
        title(axheader,descr,'FontWeight','bold','FontSize',20,'FontName','Times New Roman')
        %     text(axheader,0,0,descr,'FontWeight','bold','FontSize',30,'FontName','Times New Roman')
        accidentalsAB=numofcountsA*numofcountsB*deltat/timeinterval;
%        accidentalsAAp=numofcountsA*numofcountsAprime*deltat/timeinterval;
        accidentalsBAp=numofcountsB*numofcountsAprime*deltat/timeinterval;
%        accidentalsBBp=numofcountsB*numofcountsBprime*deltat/timeinterval;
        accidentalsABp=numofcountsA*numofcountsBprime*deltat/timeinterval;
        accidentalsApBp=numofcountsAprime*numofcountsBprime*deltat/timeinterval;
        descraccAB = ['Acc AB=',num2str(accidentalsAB)];
        title(axAB,descraccAB,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
%        descraccAAp = ['Acc AA`=',num2str(accidentalsAAp)];
%        title(axAAp,descraccAAp,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
        descraccBAp = ['Acc BA`=',num2str(accidentalsBAp)];
        title(axBAp,descraccBAp,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
%        descraccBBp = ['Acc BB`=',num2str(accidentalsBBp)];
%        title(axBBp,descraccBBp,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
        descraccABp = ['Acc AB`=',num2str(accidentalsABp)];
        title(axABp,descraccABp,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
        descraccApBp = ['Acc A`B`=',num2str(accidentalsApBp)];
        title(axApBp,descraccApBp,'FontWeight','bold','FontSize',15,'FontName','TimesNew Roman')
        drawnow

        %----------------------------------------------------------------------


        %% Storing Data in the resultsmatrix and finally in xlsx file

        resultsmatrix(count,1)=numofcounts(1,1);
        resultsmatrix(count,2)=numofcounts(1,2);
        resultsmatrix(count,3)=numofcounts(1,3);
        resultsmatrix(count,4)=numofcounts(1,4);
        resultsmatrix(count,5)=numofcounts(1,5);
        resultsmatrix(count,6)=numofcounts(1,6);
        resultsmatrix(count,7)=numofcounts(1,7);
        resultsmatrix(count,8)=numofcounts(1,8);
        %________________________________________________________________________
        % writing results gradually into the "Gradual Results' sheet in excel
        % file
        warning('off','MATLAB:xlswrite:AddSheet');
        % to suppress the warning when the sheet name is not in excel file.
        countt=num2str((stateindexi-1)*(numofmeasurements)+count+2);% to go two lines further (count+1)in excel (because of the header)
        xlrange2=strcat('A',countt);
        % xlswrite(nams',[resultsmatrix(count,1:2),resultsmatrix(count,5),accidentalsAB],Sheet1,xlrange2);
%        xlswrite(nams,[Mcurr,resultsmatrix(count,1:8),accidentalsAB,accidentalsAAp,accidentalsBBp,accidentalsApBp],Sheet1,xlrange2);
        xlswrite(nams,[Mcurr,resultsmatrix(count,1:8),accidentalsAB,accidentalsBAp,accidentalsABp,accidentalsApBp],Sheet1,xlrange2);
        count = count +1;

    end

    fclose(scounter);  % close the serial port after the inner loop ends.

    if stateindexi~=numofstates
        close all
    end

    % Writing the average of the measurement results for the state into "Total
    % Results" sheet
    countt=num2str((stateindexi-1)*2+3);
    xl2range2=strcat('A',countt);
    % accidentalstotAB=sum(resultsmatrix(1:numofmeasurements,1))*sum(resultsmatrix(1:numofmeasurements,2))*deltat/(numofmeasurements*timeinterval);
    % accidentalstotAAp=sum(resultsmatrix(1:numofmeasurements,1))*sum(resultsmatrix(1:numofmeasurements,3))*deltat/(numofmeasurements*timeinterval);
    % accidentalstotBBp=sum(resultsmatrix(1:numofmeasurements,2))*sum(resultsmatrix(1:numofmeasurements,4))*deltat/(numofmeasurements*timeinterval);
    % accidentalstotApBp=sum(resultsmatrix(1:numofmeasurements,2))*sum(resultsmatrix(1:numofmeasurements,3))*deltat/(numofmeasurements*timeinterval);
    % xlswrite(nams,[sum(resultsmatrix(1:numofmeasurements,1)),sum(resultsmatrix(1:numofmeasurements,2)),sum(resultsmatrix(1:numofmeasurements,3)),...
    %     sum(resultsmatrix(1:numofmeasurements,4)),sum(resultsmatrix(1:numofmeasurements,5)),sum(resultsmatrix(1:numofmeasurements,6)),...
    %     sum(resultsmatrix(1:numofmeasurements,7)),sum(resultsmatrix(1:numofmeasurements,8)),accidentalstotAB,accidentalstotAAp,accidentalstotBBp,accidentalstotApBp],Sheet2,xl2range2)
    pause(statepause);
    count=1;

end
writeline(sPacific,'gh');
fclose(scounter);
delete(scounter);
clear s;

%% writing date and time of the results into the excle files

timeheader={'year','month','day','hour','minute','seconds'};

% "Gradual Results" sheet
countt=num2str(numofstates*(numofmeasurements)+3);
xlrange2=strcat('A',countt);
xlswrite(nams,timeheader,Sheet1,xlrange2)
countt=num2str(numofstates*(numofmeasurements)+4);
xlrange2=strcat('A',countt);
xlswrite(nams,clockt,Sheet1,xlrange2)

parameterheader={'Minitial','Mfinal','Minc','Time Interval','Coincidence Time (ns)'};
countt=num2str(numofstates*(numofmeasurements)+5);
xlrange2=strcat('A',countt);
xlswrite(nams,parameterheader,Sheet1,xlrange2)

parameters=[Mstart,Mend,Minc,timeinterval,Tcoinc];
countt=num2str(numofstates*(numofmeasurements)+6);
xlrange2=strcat('A',countt);
xlswrite(nams,parameters,Sheet1,xlrange2)
% "Total Results" sheet
%xlrangetimeheader=strcat('A',num2str(numofstates*2+2));
%xlrangetime=strcat('A',num2str(numofstates*2+3));
%xlswrite(nams,timeheader,Sheet2,xlrangetimeheader)
%xlswrite(nams,clockt,Sheet2,xlrangetime)

% save to "resultsmatrix.txt" file
% namstxt=strcat(nams,'.txt');
% save(namstxt,'resultsmatrix','-ascii')

