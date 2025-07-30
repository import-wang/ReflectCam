#!/usr/bin/env python3
from PIL import Image, ImageDraw
import sys

def add_rounded_corners(image_path, output_path, radius_ratio=0.2):
    """给图片添加圆角效果"""
    # 打开图片
    img = Image.open(image_path).convert("RGBA")
    
    # 获取图片尺寸
    width, height = img.size
    
    # 计算圆角半径（相对于图片尺寸的比例）
    radius = int(min(width, height) * radius_ratio)
    
    # 创建一个带圆角的遮罩
    mask = Image.new('L', (width, height), 0)
    draw = ImageDraw.Draw(mask)
    
    # 绘制圆角矩形
    draw.rounded_rectangle([(0, 0), (width, height)], radius=radius, fill=255)
    
    # 创建输出图片
    output = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    # 保存图片
    output.save(output_path, 'PNG')
    print(f"圆角图标已保存到: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python3 add_rounded_corners.py <输入图片> <输出图片>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    add_rounded_corners(input_path, output_path)