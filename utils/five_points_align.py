
import numpy as np
import scipy.ndimage
import os
import PIL.Image
from cv2 import cv2
from  skimage import  transform as trans


def image_align(src_file, dst_file, face_landmarks, output_size=1024, transform_size=4096, enable_padding=True,
                x_scale=1, y_scale=1, em_scale=0.1, alpha=False):
    # Align function from FFHQ dataset pre-processing step
    # https://github.com/NVlabs/ffhq-dataset/blob/master/download_ffhq.py

    lm = np.array(face_landmarks)
    lm_chin = lm[0: 17]  # left-right
    lm_eyebrow_left = lm[17: 22]  # left-right
    lm_eyebrow_right = lm[22: 27]  # left-right
    lm_nose = lm[27: 31]  # top-down
    lm_nostrils = lm[31: 36]  # top-down
    lm_eye_left = lm[36: 42]  # left-clockwise
    lm_eye_right = lm[42: 48]  # left-clockwise
    lm_mouth_outer = lm[48: 60]  # left-clockwise
    lm_mouth_inner = lm[60: 68]  # left-clockwise

    # Calculate auxiliary vectors.
    eye_left = np.mean(lm_eye_left, axis=0)

    eye_right = np.mean(lm_eye_right, axis=0)
    eye_avg = (eye_left + eye_right) * 0.5
    eye_to_eye = eye_right - eye_left
    nose_center = lm[30]
    mouth_left = lm_mouth_outer[0]
    mouth_right = lm_mouth_outer[6]

    mouth_avg = (mouth_left + mouth_right) * 0.5
    eye_to_mouth = mouth_avg - eye_avg
    SRC_FIVE_POINTS = np.array([eye_left, eye_right, nose_center, mouth_left, mouth_right],dtype=np.float32)

    # Five key positions of normalization
    FIVE_NORMALIZED_POINTS = np.array([[0.31556875000000000, 0.4615741071428571],
                                      [0.68262291666666670, 0.4615741071428571],
                                      [0.50026249999999990, 0.6405053571428571],
                                      [0.34947187500000004, 0.8246919642857142],
                                      [0.65343645833333330, 0.8246919642857142]],dtype=np.float32)

   # img = PIL.Image.open(src_file).convert('RGBA').convert('RGB')
    img = cv2.imread(src_file)
    print('img.shpe:',img.shape)
    # size about img
    #img_size = np.array([img.size[0], img.size[1]])
    height,width = img.shape[0:2]
    # REFERENCE_FACIAL_POINTS 参照目标
    REFERENCE_FACIAL_POINTS = [[408.66666667, 450.16666667],
                               [638.        , 457.83333333],
                               [536., 571.],
                               [428., 728.],
                               [614., 732.] ]

    print(REFERENCE_FACIAL_POINTS)

    # Transform.
    transformation = trans.SimilarityTransform()
    res = transformation.estimate(SRC_FIVE_POINTS,REFERENCE_FACIAL_POINTS)
    M = transformation.params
    print('res:',res)
    print('M:',M[:,:])
    new_img = cv2.warpAffine(img,M[0:2,:],dsize=[4096,4096])
    print(new_img)
    # Save aligned image.
    print('123')
    cv2.imwrite(dst_file,new_img)
