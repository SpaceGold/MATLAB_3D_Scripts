fn = 'D:\He Lab Viz2\Math\not\ROI_9_9_5SDA\ROI_9_9_5SDA_segch2_ekr2_dkrbb2_dkrc2_min_P_bb0.3_max_p_bk0.8_minBBsize8011_Raw_ROI9_P14.view.tif';
im = readtiff(fn);

[vol, skel, dtm, SkelcoordXYZ, SkelRadius] = GU_calcSkelDistMap(im, 'Fill', false, 'minConnVox', 50, 'dierr', 1, 'zAniso', 1, 'RemoveEdgeVoxels', 0);
writetiff(dtm, [fn(1:end-4) '_dtm.tif']);

T = thresholdOtsu(dtm(dtm>0));

sda = im;
sda(dtm>T) = 0;
writetiff(sda, [fn(1:end-4) '_dtm_sda2.tif']);

%
[vol, skel, dtm2, SkelcoordXYZ, SkelRadius] = GU_calcSkelDistMap(sda, 'Fill', false, 'minConnVox', 50, 'dierr', 1, 'zAniso', 1, 'RemoveEdgeVoxels', 0);
writetiff(dtm2, [fn(1:end-4) '_dtm_sda_dtm.tif']);