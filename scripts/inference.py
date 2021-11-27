import argparse

import torch
import numpy as np
import sys
import os
import dlib

sys.path.append('')
from configs import data_configs, paths_config

from datasets.inference_dataset import InferenceDataset
from torch.utils.data import DataLoader
from utils.model_utils import setup_model
from utils.common import tensor2im
from utils.alignment import align_face
from PIL import Image


def main(args):
    net, opts = setup_model(args.ckpt, device)
    is_cars = 'cars_' in opts.dataset_type
    generator = net.decoder
    generator.eval()
    args, data_loader = setup_data_loader(args, opts)
    # 是否上batch
    Batch = args.Batch
    # Check if latents exist
    latents_file_path = os.path.join(args.save_latent_dir, 'latents.pt')
    # if exists
    if os.path.exists(latents_file_path):
        # latent_codes = torch.load(latents_file_path).to(device)
        os.remove(latents_file_path)

    latent_codes = get_all_latents(net, data_loader, args.n_sample, is_cars=is_cars, Batch=Batch)
    # 将仿射参数的文件集成一个文件
    if args.path_integrate_Affine is not None:
        file_name = 'integrated_affine.npy'
        integrate_npy(args.path_integrate_Affine, file_name)

    if Batch == False:
        print('latent_code.shape', latent_codes.shape)
        torch.save(latent_codes, latents_file_path)

    if not args.latents_only:
        generate_inversions(args, generator, latent_codes, is_cars=is_cars)


def setup_data_loader(args, opts):
    dataset_args = data_configs.DATASETS[opts.dataset_type]
    transforms_dict = dataset_args['transforms'](opts).get_transforms()
    images_path = args.images_dir if args.images_dir is not None else dataset_args['test_source_root']

    print(f"images path: {images_path}")
    align_function = None
    if args.align:
        align_function = run_alignment
    test_dataset = InferenceDataset(root=images_path,
                                    transform=transforms_dict['transform_test'],
                                    preprocess=align_function,
                                    opts=opts)
    print('test_dataset:', test_dataset)
    data_loader = DataLoader(test_dataset,
                             batch_size=args.batch,
                             shuffle=False,
                             num_workers=2,
                             drop_last=True)

    print(f'dataset length: {len(test_dataset)}')

    if args.n_sample is None:
        args.n_sample = len(test_dataset)
    return args, data_loader


# 获得code的关键代码
def get_latents(net, x, is_cars=False):
    codes = net.encoder(x)
    print('net.opts.start_from_latent_avg:', net.opts.start_from_latent_avg)
    print('codes.ndim:', codes.ndim)
    if net.opts.start_from_latent_avg:
        if codes.ndim == 2:
            codes = codes + net.latent_avg.repeat(codes.shape[0], 1, 1)[:, 0, :]

        else:
            codes = codes + net.latent_avg.repeat(codes.shape[0], 1, 1)
    if codes.shape[1] == 18 and is_cars:
        codes = codes[:, :16, :]
    return codes


# 获取所有Latents拼接起来
def get_all_latents(net, data_loader, n_images=None, is_cars=False, Batch=False):
    all_latents = []
    i = 0
    with torch.no_grad():
        for batch in data_loader:
            if n_images is not None and i > n_images:
                break
            x = batch
            inputs = x.to(device).float()
            latents = get_latents(net, inputs, is_cars)
            all_latents.append(latents)
            i += len(latents)
            # 从0开始,如果需要Batch 则一个一个存储
            if Batch == True:
                latent_name = '%05d.pt' % (i)
                torch.save(latents, os.path.join(args.path_file_pt, latent_name))
    return torch.cat(all_latents)


# 保存图片
def save_image(img, save_dir, idx):
    im_save_path = os.path.join(save_dir, f"{idx:05d}.jpg")
    # 演变回去
    # inv_M = np.linalg.inv(param_M)
    # img = img.transform((1620, 1620), Image.AFFINE, inv_M[0:2, :].flatten(), Image.BILINEAR)
    result = tensor2im(img)
    Image.fromarray(np.array(result)).save(im_save_path)


@torch.no_grad()
def generate_inversions(args, g, latent_codes, is_cars):
    print('Saving inversion images')
    # 生成反演图像
    # inversions_directory_path = os.path.join(args.save_dir, 'inversions')
    inversions_directory_path = os.path.join(args.save_dir)
    os.makedirs(inversions_directory_path, exist_ok=True)
    # unsqueeze 是对维度进行扩充
    for i in range(args.n_sample):
        imgs, _ = g([latent_codes[i].unsqueeze(0)], input_is_latent=True, randomize_noise=False, return_latents=True)
        if is_cars:
            imgs = imgs[:, :, 64:448, :]
        save_image(imgs[0], inversions_directory_path, i + 1)


def run_alignment(image_path):
    predictor = dlib.shape_predictor(paths_config.model_paths['shape_predictor'])
    aligned_image = align_face(filepath=image_path, predictor=predictor)
    print("Aligned image has shape: {}".format(aligned_image.size))
    return aligned_image


def integrate_npy(path_file, result_name):
    files = os.listdir(path_file)
    files.sort()
    result_npy = None
    for file in files:
        if result_npy is not None:
            result_npy = np.concatenate((result_npy, np.load(path_file + file)[np.newaxis, :, :]))
        else:
            result_npy = np.load(path_file + file)
            result_npy = result_npy[np.newaxis, :, :]
        # 删除文件
        os.remove(path_file + file)
    print('result_py:', result_npy.shape)
    np.save(path_file + result_name, result_npy)


if __name__ == "__main__":
    device = "cuda"

    parser = argparse.ArgumentParser(description="Inference")
    parser.add_argument("--images_dir", type=str, default=None,
                        help="The directory of the images to be inverted")
    parser.add_argument("--save_dir", type=str, default=None,
                        help="The directory to save inversion images. ")
    parser.add_argument("--save_latent_dir", type=str, default=None,
                        help="The directory to save the latent codes. ")
    parser.add_argument("--batch", type=int, default=8, help="batch size for the generator")
    parser.add_argument("--n_sample", type=int, default=None, help="number of the samples to infer.")
    parser.add_argument("--latents_only", action="store_true", help="infer only the latent codes of the directory")
    parser.add_argument("--align", action="store_true", help="align face images before inference")
    parser.add_argument("--ckpt", metavar="CHECKPOINT", help="path to generator checkpoint")
    parser.add_argument("--Batch", type=bool, default=False, help="if need batch ")
    parser.add_argument("--path_integrate_Affine", type=str, default=None,
                        help="help to integrate the param of Affine ")
    parser.add_argument("--path_file_pt", type=str, default=r'./result/file-pt/',
                        help="path to save %05d.pt if use Batch")

    args = parser.parse_args()
    main(args)
