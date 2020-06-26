function [ doses, radii, centre ] = plot_radial_dose(patient_table, id)
%initialisations
doses = patient_table.dose(patient_table.ID == id);
xmm = patient_table.xmm(patient_table.ID == id);
ymm = patient_table.ymm(patient_table.ID == id);
zmm = patient_table.zmm(patient_table.ID == id);

%calculate centre
xmm_avg = mean(xmm);
ymm_avg = mean(ymm);
zmm_avg = mean(zmm);
centre = [ xmm_avg, ymm_avg, zmm_avg ];

%calculate distances from centre
xmm_dist = xmm - xmm_avg;
ymm_dist = ymm - ymm_avg;
zmm_dist = zmm - zmm_avg;

%calc radii using distance formula
radii = sqrt(xmm_dist.^2 + ymm_dist.^2 + zmm_dist.^2);

%plot
h = scatter(radii, doses,1,'.','MarkerFaceColor','auto');%'flat');
%scatterhist(radii, doses);
xlabel('Radius (mm)');
ylabel('Dose (Gy)');

[N,Xedges,Yedges] = histcounts2(radii,doses);