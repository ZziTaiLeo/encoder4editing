import os

import cv2
import numpy
import numpy as np
from skimage import transform
import PIL.Image
import torch

path_to_images = r'./result/inference_inversions/'
path_to_inv_params = r'result/npy/integrated_affine.npy'
inv_M = np.load(path_to_inv_params)
files = os.listdir(path_to_images)
files.sort()
#
idx = 0
for file in files:
    cv_img = cv2.imread(path_to_images+file)
    new_img = cv2.warpAffine(cv_img, inv_M[idx,0:2,:],dsize=(720,1280))
    idx+=1
    result_path = 'result/inversion_recover/'
    cv2.imwrite(result_path+file, new_img)
