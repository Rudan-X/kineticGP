function simulation_from_predicted_parameters_CVbased(t)
param_type="original";
env="control";
thres=[12.5,10,7.5,6,5,4,3,2,1,0];
thre=thres(t);
KE_type="equilibrator";
% method="rrBLUP";
method="BGLR";
initial=false;
folder="equilibrator_parameters_1round";
%%
folderdir='C:/Users/Rudan/Documents/MATLAB_Drive/KineticGP/';
if ~exist(folderdir, 'dir')
    folderdir='/work/xu2/KineticGP/';
end
addpath(strcat(folderdir,'analysis_publication/'))
addpath(strcat(folderdir,'C4_dynamic_model/'))
addpath(strcat(folderdir,'parameterization/'))

init_sol0=load_initial_solution();
nvar=length(init_sol0);

param_name=load_parameter_name();
vmaxind=find(contains(param_name,'Vm1'),1):find(contains(param_name,'Vm35_Hep'));


fieldcond=readtable("../data/processed_data/Testing_Asat3years_fieldcond_accession.csv",'Delimiter',',','VariableNamingRule','preserve');

%% load result for 2021, which uses parameters predicted from BLUPs of optimized values across 2022 and 2023
all_traits=readtable(strcat("../results/",folder,"/optimized_parameters_",KE_type,"_BLUP.csv"),'Delimiter',',','VariableNamingRule','preserve');
all_traits(:,1)=[];
training_params=table2array(all_traits)';
np=size(all_traits,2);

predicted_params=readtable(strcat("../results/",folder,"/",param_type,"_predicted_parameters_BLUP_",KE_type,"_",method,".csv"),"TreatAsMissing","NA");
predicted_lines21=predicted_params{:,1};
predicted_params=predicted_params(:,2:end);
predicted_params=table2array(predicted_params);

if method=="BGLR"
    ind2=find(isnan(predicted_params(1,:)));
    if ~isempty(ind2)
        predicted_params(:,ind2)=repmat(mean(training_params(ind2,:),2)',size(predicted_params,1),1);
    end
end

CVvec=zeros(np,1);
for k=1:np
    CVvec(k,1)=std(predicted_params(:,k),"omitnan")/mean(predicted_params(:,k),"omitnan")*100;
end

goodind=find(CVvec>=thre);

new_params=repmat(mean(training_params,2),1,length(predicted_lines21));
new_params(goodind,:)=predicted_params(:,goodind)';

var21=new_params;
AQ=readtable("../data/processed_data/Testing_Asat21_accession.csv");
testing21=AQ{:,"Accession"};
%%

all_traits=readtable(strcat("../results/",folder,"/optimized_parameters_",KE_type,".csv"),'Delimiter',',','VariableNamingRule','preserve');
all_traits(:,1)=[];
training_params=table2array(all_traits)';
np=size(all_traits,2);

predicted_params=readtable(strcat("../results/",folder,"/",param_type,"_predicted_parameters_",KE_type,"_",method,".csv"),"TreatAsMissing","NA");
predicted_lines22=predicted_params{:,1};
predicted_lines23=predicted_params{:,1};

predicted_params=predicted_params(:,2:end);
predicted_params=table2array(predicted_params);

if method=="BGLR"
    ind2=find(isnan(predicted_params(1,:)));
    if ~isempty(ind2)
        predicted_params(:,ind2)=repmat(mean(training_params(ind2,:),2)',size(predicted_params,1),1);
    end
end

CVvec=zeros(np,1);
for k=1:np
    CVvec(k,1)=std(predicted_params(:,k),"omitnan")/mean(predicted_params(:,k),"omitnan")*100;
end

goodind=find(CVvec>=thre);

new_params=repmat(mean(training_params,2),1,length(predicted_lines22));
new_params(goodind,:)=predicted_params(:,goodind)';

var22=new_params(1:nvar,:);
var23=var22;
var23(vmaxind,:)=new_params((nvar+1):end,:);

%% if Wang parameters are used to simulate
if initial
    var21=repmat(init_sol0,1,size(var21,2));
    var22=repmat(init_sol0,1,size(var22,2));
    var23=repmat(init_sol0,1,size(var23,2));
end
%%
AQ=readtable("../data/processed_data/Testing_AQcurves_years22&23_accession.csv");
testing22=AQ{AQ{:,"Year"}==2022,"Accession"};
testing23=AQ{AQ{:,"Year"}==2023,"Accession"};
if env=="field"
    simA21=zeros(length(testing21),7);
    simA22=zeros(length(testing22),7);
    simA23=zeros(length(testing23),7);
    sim_var=["Year";"Accession";strcat("PAR_",string([301,1800,1100,500,300,150,50]))'];

elseif env=="control"
    simA21=zeros(length(testing21),6);
    simA22=zeros(length(testing22),6);
    simA23=zeros(length(testing23),6);
    sim_var=["Year";"Accession";strcat("PAR_",string([1800,1100,500,300,150,50]))'];

end
%%
for k=1:length(testing21)
    fprintf("Accession %d\n",k)
    [~,ind]=ismember(testing21(k),predicted_lines21);

    if sum(isnan(var21(:,ind)))<1 % no SNP data for the accessions with NaN in predicted params
        if env=="field"
            indT=find(strcmp(fieldcond{:,"Accession"},testing21(k)));
            indT=indT(fieldcond{indT,"Year"}==2021);
            if isempty(indT)
                simA21(k,:)=NaN;
            else
                Tfield=fieldcond{indT,"meanTemperature"};
                simA21(k,:)=simulate_AQ_field(var21(:,ind),Tfield,KE_type);
            end
        elseif env=="control"
            simA21(k,:)=simulate_AQ(var21(:,ind),25,KE_type);
        end
    else
        simA21(k,:)=NaN;
    end
end


for k=1:length(testing22)
    fprintf("Accession %d\n",k)
    [~,ind]=ismember(testing22(k),predicted_lines22);

    if sum(isnan(var22(:,ind)))<1 % no SNP data for the accessions with NaN in predicted params
        if env=="field"
            indT=find(strcmp(fieldcond{:,"Accession"},testing22(k)));
            indT=indT(fieldcond{indT,"Year"}==2022);
            if isempty(indT)
                simA22(k,:)=NaN;
            else
                Tfield=fieldcond{indT,"meanTemperature"};
                simA22(k,:)=simulate_AQ_field(var22(:,ind),Tfield,KE_type);
            end
        elseif env=="control"
            simA22(k,:)=simulate_AQ(var22(:,ind),25,KE_type);
        end
    else
        simA22(k,:)=NaN;
    end
end

for k=1:length(testing23)
    fprintf("Accession %d\n",k)
    [~,ind]=ismember(testing23(k),predicted_lines23);

    if sum(isnan(var23(:,ind)))<1
        if env=="field"
            indT=find(strcmp(fieldcond{:,"Accession"},testing23(k)));
            indT=indT(fieldcond{indT,"Year"}==2023);
            if isempty(indT)
                simA23(k,:)=NaN;
            else
                Tfield=fieldcond{indT,"meanTemperature"};
                simA23(k,:)=simulate_AQ_field(var23(:,ind),Tfield,KE_type);
            end
        elseif env=="control"
            simA23(k,:)=simulate_AQ(var23(:,ind),25,KE_type);
        end
    else
        simA23(k,:)=NaN;
    end
end

simA=[simA21;simA22;simA23];
accs=string([testing21;testing22;testing23]);
years=[2021*ones(length(testing21),1);2022*ones(length(testing22),1);2023*ones(length(testing23),1)];

if method=="rrBLUP"
    ml="";
elseif method=="BGLR"
    ml="BGLR_";
end

if initial==true
    filen=strcat("../GenomicPrediction/testing/",ml,param_type,"_",KE_type,"_Wang_",env,"_CV",string(thre),".csv");
else
    filen=strcat("../GenomicPrediction/testing/",ml,param_type,"_",KE_type,"_",env,"_CV",string(thre),".csv");
end
writetable(array2table([years,accs,simA],"VariableNames",sim_var),filen,'WriteVariableNames',true,'WriteRowNames',true);

