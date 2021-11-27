import numpy as np
import PIL
import PIL.Image
import scipy
import scipy.ndimage
import dlib
import  cv2
from skimage import transform as tran


def get_landmark(filepath, predictor):
    """get landmark with dlib
    :return: np.array shape=(68, 2)
    """
    detector = dlib.get_frontal_face_detector()

    img = dlib.load_rgb_image(filepath)
    dets = detector(img, 1)

    for k, d in enumerate(dets):
        shape = predictor(img, d)

    t = list(shape.parts())
    a = []
    for tt in t:
        a.append([tt.x, tt.y])
    lm = np.array(a)
    return lm


def align_face(filepath, predictor):
    """
    :param filepath: str
    :return: PIL Image
    """

    lm = get_landmark(filepath, predictor)

    lm_chin = lm[0: 17]  # left-right
    lm_eyebrow_left = lm[17: 22]  # left-right
    lm_eyebrow_right = lm[22: 27]  # left-right
    lm_nose = lm[27: 31]  # top-down
    lm_nostrils = lm[31: 36]  # top-down
    lm_eye_left = lm[36: 42]  # left-clockwise
    lm_eye_right = lm[42: 48]  # left-clockwise
    lm_mouth_outer = lm[48: 60]  # left-clockwise
    lm_mouth_inner = lm[60: 68]  # left-clockwise
    nose_center = lm[30]
    # Calculate auxiliary vectors.
    eye_left = np.mean(lm_eye_left, axis=0)
    eye_right = np.mean(lm_eye_right, axis=0)
    eye_avg = (eye_left + eye_right) * 0.5
    eye_to_eye = eye_right - eye_left
    mouth_left = lm_mouth_outer[0]
    mouth_right = lm_mouth_outer[6]
    mouth_avg = (mouth_left + mouth_right) * 0.5

    eye_to_mouth = mouth_avg - eye_avg

    # Choose oriented crop rectangle.
    x = eye_to_eye - np.flipud(eye_to_mouth) * [-1, 1]
    x /= np.hypot(*x)
    x *= max(np.hypot(*eye_to_eye) * 2.0, np.hypot(*eye_to_mouth) * 1.8)
    y = np.flipud(x) * [-1, 1]
    c = eye_avg + eye_to_mouth * 0.1
    quad = np.stack([c - x - y, c - x + y, c + x + y, c + x - y])
    qsize = np.hypot(*x) * 2

    # read image
    img = PIL.Image.open(filepath)

    output_size = 1024
    transform_size = 4096
    enable_padding = True

    # Shrink.
    shrink = int(np.floor(qsize / output_size * 0.5))
    if shrink > 1:
        rsize = (int(np.rint(float(img.size[0]) / shrink)), int(np.rint(float(img.size[1]) / shrink)))  # rint函数是四舍五入取整
        img = img.resize(rsize, PIL.Image.ANTIALIAS)
        quad /= shrink
        qsize /= shrink
    # Crop(left, upper, right, lower)
    # np.floor返回不大于输入参数的最大整数，np.ceil返回不小于输入参数的最小整数
    border = max(int(np.rint(qsize * 0.1)), 3)
    # 取包括四边形的最小矩形  取quad里左上和右下
    crop = (int(np.floor(min(quad[:, 0]))), int(np.floor(min(quad[:, 1]))), int(np.ceil(max(quad[:, 0]))),
            int(np.ceil(max(quad[:, 1]))))  # crop = (-411, 241, 2937, 3589)
    # 增加border
    crop = (max(crop[0] - border, 0), max(crop[1] - border, 0), min(crop[2] + border, img.size[0]),
            min(crop[3] + border, img.size[1]))  # crop = (0,0,2316,3088)
    SRC_FIVE_POINTS = np.array([eye_left, eye_right, nose_center, mouth_left, mouth_right], np.float32)

    REFERENCE_FACIAL_POINTS = np.array([[408.66666667, 450.16666667],
                                        [638., 457.83333333],
                                        [536., 571.],
                                        [428., 728.],
                                        [614., 732.]], dtype=np.float32)

    # Pad. 填充数据
    pad = (int(np.floor(min(quad[:, 0]))), int(np.floor(min(quad[:, 1]))), int(np.ceil(max(quad[:, 0]))),
           int(np.ceil(max(quad[:, 1]))))
    pad = (max(-pad[0] + border, 0), max(-pad[1] + border, 0), max(pad[2] - img.size[0] + border, 0),
           max(pad[3] - img.size[1] + border, 0))
    if enable_padding and max(pad) > border - 4:
        pad = np.maximum(pad, int(np.rint(qsize * 0.3)))  # np.maximum()取对应位置上的较大值，np.minimum 取对应位置上的较小值
        # 对剪切区域溢出到img图片x轴负方向（即：第二、三象限）和y轴负方向（即：第三、四象限）的部分，用图像数据进行填充
        # 下面的操作实际上是在当前图像区域的四周，分别填充了pad[0]、pad[1]、pad[2]、pad[3]宽度的数据，填充方法为reflect
        img = np.pad(np.float32(img), ((pad[1], pad[3]), (pad[0], pad[2]), (0, 0)), 'reflect')

        # y, x, _为三维正交向量，y为列向量[[1], [2], ...[h]]，x为行向量[[1, 2, ...w]]
        # (x, y)集合定义了整张图片的像素位置
        h, w, _ = img.shape
        y, x, _ = np.ogrid[:h, :w, :1]
        # mask用于把Pad的边界数据标识出来
        mask = np.maximum(1.0 - np.minimum(np.float32(x) / pad[0], np.float32(w - 1 - x) / pad[2]),
                          1.0 - np.minimum(np.float32(y) / pad[1], np.float32(h - 1 - y) / pad[3]))

        blur = qsize * 0.02
        # 高斯滤波让它们一定程度上变模糊，然后相减，提取模糊信息, 并将模糊信息添加到Pad的边界数据上
        img += (scipy.ndimage.gaussian_filter(img, [blur, blur, 0]) - img) * np.clip(mask * 3.0 + 1.0, 0.0, 1.0)
        img += (np.median(img, axis=(0, 1)) - img) * np.clip(mask, 0.0, 1.0)  # np.median()返回数组元素的中位数
        img = np.uint8(np.clip(np.rint(img), 0, 255))
        quad += pad[:2]
        SRC_FIVE_POINTS +=  [pad[0], pad[1]]

    # 平移回去
    # PIL转换为numpy数组格式，并使用opencv读入
    img_opencv = np.array(img)
    opencvImage = cv2.cvtColor(img_opencv, cv2.COLOR_RGB2BGR)
    transform = tran.SimilarityTransform()
    # 获得仿射变换参数并变换矩阵
    res = transform.estimate(SRC_FIVE_POINTS, REFERENCE_FACIAL_POINTS)
    M = transform.params
    new_img = cv2.warpAffine(opencvImage, M[0:2, :], dsize=[output_size, output_size])
    # 计算逆矩阵，且平移，并保存。
    inv_M = np.linalg.inv(M)
    if enable_padding and max(pad) > border - 4:
        inv_M[0, 2] -= pad[0]
        inv_M[1, 2] -= pad[1]
    # Save aligned image.
    #这里可以保存到一个文件里
    np.save('result/npy/'+filepath.split('/')[-1].split('.')[0] + '.npy', inv_M)
    cv2Pli = PIL.Image.fromarray(cv2.cvtColor(new_img,cv2.COLOR_BGR2RGB))
    cv2.imwrite('result/aligned_images/'+filepath.split('/')[-1].split('.')[0]+'.jpg', new_img)

    return cv2Pli


'''
瑕疵：  用Image读图片并操作图片，转cv2仿射，又转回image
'''
