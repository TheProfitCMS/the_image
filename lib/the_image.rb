require_relative 'the_image/version'
require 'mini_magick'

module TheImage
  # Helpers
  def path_to_file file_path
    file_path.split('/')[0...-1].join('/')
  end

  def destroy_file file_path
    FileUtils.rm(file_path , force: true)
  end

  def destroy_dir dir_path
    FileUtils.rm_rf dir_path
  end

  def create_path_for_file file_path
    FileUtils.mkdir_p path_to_file(file_path)
  end

  def destroy_dir_of_file file_path
    FileUtils.rm_rf path_to_file(file_path)
  end

  # Main methods
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

    image  = ::MiniMagick::Image.open src
    image.format(format.to_s.downcase) if format

    image = instance_exec(image, opts, &block)
    image.write dest
  end

  # Image manipulate
  # Resizing can be wrong when .EXT of file is wrong
  def strict_resize image, w, h
    image.resize "#{ w }x#{ h }!"
    image
  end

  def resize image, w, h
    image.resize "#{ w }x#{ h }"
    image
  end

  def rotate image, angle
    image.rotate angle
    image
  end

  def rotate_left image
    rotate image, '-90'
  end

  def rotate_right image
    rotate image, '90'
  end

  def biggest_side_not_bigger_than image, size
    if landscape?(image)
      image.resize("#{ size }x") if image[:width] > size.to_i
    else
      image.resize("x#{ size }") if image[:height] > size.to_i
    end

    image
  end

  def strip image
    image.strip
    image
  end

  def auto_orient image
    image.auto_orient
    image
  end

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
    image
  end

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
    image
  end
end
