require_relative 'the_image/version'
require 'mini_magick'

module TheImage
  def chmod_mask
    0644
  end

  # HELPERS
  def image_open path
    ::MiniMagick::Image.open path
  end

  def path_to_file file_path
    file_path.split('/')[0...-1].join('/')
  end

  def create_path_for_file file_path
    FileUtils.mkdir_p path_to_file(file_path)
  end

  def create_path_for_dir path
    FileUtils.mkdir_p path
  end

  def destroy_file file_path
    FileUtils.rm(file_path , force: true)
  end

  def destroy_dir_of_file file_path
    FileUtils.rm_rf path_to_file(file_path)
  end

  def destroy_dir dir_path
    FileUtils.rm_rf dir_path
  end

  # BASE METHODS
  def landscape? image
    image[:width] > image[:height]
  end

  def portrait? image
    image[:width] < image[:height]
  end

  def manipulate opts = {}, &block
    src    = opts[:src]
    dest   = opts[:dest]
    format = opts[:format]
    image  = image_open src

    image.format(format.to_s.downcase) if format
    image = instance_exec(image, opts, &block)

    create_path_for_file(dest)
    image.write dest

    FileUtils.chmod(chmod_mask, dest)
  end

  # Image manipulate
  # Resizing can be wrong when .EXT of file is wrong
  def strict_resize image, w, h
    image.resize "#{ w }x#{ h }!"
  end

  def resize image, w, h
    image.resize "#{ w }x#{ h }"
  end

  def resize_w image, w
    image.resize "#{ w }x"
  end

  def resize_h image, h
    image.resize "x#{ h }"
  end

  def rotate image, angle
    image.rotate angle
  end

  def rotate_left image
    rotate image, '-90'
  end

  def rotate_right image
    rotate image, '90'
  end

  # OPTIMIZE

  def strip image
    image.strip
  end

  def auto_orient image
    image.auto_orient
  end

  def optimize image, quality = 85, depth = 8, interlace = :plane
    image.combine_options do |c|
      c.quality   quality.to_s
      c.depth     depth.to_s
      c.interlace interlace.to_s
    end
  end

  # USEFUL METHODS

  def biggest_side_not_bigger_than image, size
    if landscape?(image)
      image.resize("#{ size }x") if image[:width] > size.to_i
    else
      image.resize("x#{ size }") if image[:height] > size.to_i
    end
  end

  # get rectangle form image
  def to_rect image, width, height, opts = {}
    default_opts = { valign: :center, align: :center }
    opts = default_opts.merge(opts)

    align  = opts[:align].to_sym
    valign = opts[:valign].to_sym

    w0, h0 = image[:width].to_f, image[:height].to_f
    w1, h1 = width.to_f, height.to_f
    fw, fh = w0, h0

    scale = ((w1 / w0) > (h1 / h0)) ? (w1 / w0) : (h1 / h0)

    fw = (w1 / scale).to_i
    fh = (h1 / scale).to_i

    x0 = case align
      when :center
        ((w0 - fw) / 2).to_i
      when :right
        (w0 - fw).to_i
      else
        0
    end

    y0 = case valign
      when :center
        ((h0 - fh) / 2).to_i
      when :bottom
        (h0 - fh).to_i
      else
        0
    end

    image.crop   "#{ fw }x#{ fh }+#{ x0 }+#{ y0 }"
    image.resize "#{ width }x#{ height }!"
  end

  # get rectangle from image from middle or top
  # `v_ratio_min` and `v_ratio_max` define W/H ratio
  # when we have to get middle or top part of image
  def smart_rect image, width, height, v_ratio_min = 0.625, v_ratio_max = 0.80
    scale_w = 1.0/(image.width.to_f/width.to_f)
    scale_h = 1.0/(image.height.to_f/height.to_f)
    scale   = scale_w > scale_h ? scale_w : scale_h

    ratio = scale_w/scale_h

    valign = :center
    valign = :top if ratio >= v_ratio_min && ratio <= v_ratio_max

    new_w = image.width*scale
    new_h = image.height*scale

    image = to_rect image, new_w, new_h,  { valign: :center, align: :center }
    image = to_rect image, width, height, { valign: valign,  align: :center }
  end

  # just to square
  def to_square image, size, opts = {}
    to_rect image, size, size, opts
  end

  # scale = original_iamge[:width].to_f / image_on_screen[:width].to_f
  # usually scale should be 1
  def crop image, x0 = 0, y0 = 0, w = 100, h = 100, scale = 1
    x0 = (x0.to_f * scale).to_i
    y0 = (y0.to_f * scale).to_i

    w = (w.to_f * scale).to_i
    h = (h.to_f * scale).to_i

    image.crop "#{ w }x#{ h }+#{ x0 }+#{ y0 }"
  end
end
