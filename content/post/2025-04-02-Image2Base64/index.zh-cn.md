+++
author = "Andrew Moa"
title = "一款基于Qt6的图片base64转换工具"
date = "2025-04-02"
description = ""
tags = [
    "c++",
    "python",
    "qt",
]
categories = [
    "code",
]
series = [""]
aliases = [""]
image = "/images/code-bg.jpg"
+++

经常写Markdown的小伙伴都会遇到一个问题，那就是图片存储问题。Markdown本身并不支持图片内置，传统用法一般通过外链引用本机或网络上的图片。但是当文章在网络上发表时，存储图片就成了个问题，虽然可以通过图床上传，但是操作麻烦。

好在Markdown支持通过base64[^1]编码数据渲染图片，这里根据这个功能编写了一个小工具[Image2Base64](https://github.com/AndrewMoa2005/Image2Base64)，可以方便地在图片文件和base64编码之间转换。

## 1. 软件功能

下面就是这个软件的图形界面，这个截图就是通过base64渲染的。
![4cdbc8106d0296e6261e6abdfa0b0096](data:image/png;base64,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)

软件界面左侧窗口是图片显示窗口，可以通过拖放打开图片，支持bmp、png、jpg等主流格式的图片(暂不支持gif动图显示)，支持右键菜单，支持图片放大缩小和重置等基本操作。

左侧窗口下方的`Paste`按钮可以将剪贴板中的图像数据读取并显示出来，方便通过截图软件和剪贴板交互读取图像数据。

右侧窗口是文本显示窗口，如果转换成功这里会图片对应的base64编码并显示出来。下方的Markdown复选框用于添加Markdown的图片语法标签，点击`Copy`按钮后可以将文本数据复制到剪贴板，之后就可以直接在MD文件中粘贴了。

值得注意的是，`Copy`按钮左侧的组合框可以选择base64对应的图片格式。没错，base64也是有对应格式区分的，base64本质上是将二进制编码的文本化，因此不同图片原始格式的大小所导致的base64编码长度自然不一样，甚至图片的复杂程度和压缩比等因素对base64编码长度都有影响。

右侧窗口下方的`Save as`按钮支持将图片文件以原始格式或base64编码(txt文件)存储。通过中间的两个方向按钮可以实现将图片转换成base64编码，或者将base64编码转换成图片。需要注意的是，将base64编码转换成图片时，请不要包含markdown的语法标签，否则会报错。

该软件经过测试，可以使用png格式base64编码，通过markdown语法标签在[marktext](https://github.com/marktext/marktext)和[joplin](https://joplinapp.org/)上渲染图片，其他格式不保证能成功，取决于markdown编辑器的渲染引擎。对于一般屏幕截图，推荐采用png格式。

## 2. 代码解析

### 2.1 C++实现

该软件基于Qt6实现，图片格式编码、渲染以及base64转换都是通过Qt实现的。

图片显示通过QLabel实现，重载了QLabel类[^2]，并做了一些调整。

`photolabel.h`：
```cpp
#ifndef PHOTOLABEL_H
#define PHOTOLABEL_H

#include <QObject>
#include <QLabel>
#include <QMenu>
#include <QDragEnterEvent>
#include <QDropEvent>

class PhotoLabel : public QLabel
{
	Q_OBJECT

public:
	explicit PhotoLabel(QWidget* parent = nullptr);

	void openFile(QString);     //打开图片文件
	void clearShow();           //清空显示
	void setImage(QImage&);     //设置图片
	void openAction();          //调用打开文件对话框
	void pasteAction();         //粘贴来自剪贴板的图片
	const QImage& getImage();   //调用存储的图片数据

signals:
	// 图片加载成功信号
	void imageLoadSuccess();

protected:
	void contextMenuEvent(QContextMenuEvent* event) override;   //右键菜单
	void paintEvent(QPaintEvent* event) override;               //QPaint画图
	void wheelEvent(QWheelEvent* event) override;               //鼠标滚轮滚动
	void mousePressEvent(QMouseEvent* event) override;          //鼠标摁下
	void mouseMoveEvent(QMouseEvent* event) override;           //鼠标松开
	void mouseReleaseEvent(QMouseEvent* event) override;        //鼠标发射事件
	//拖放文件
	void dragEnterEvent(QDragEnterEvent* event) override;
	void dragMoveEvent(QDragMoveEvent* event) override;
	void dropEvent(QDropEvent* event) override;

private slots:
	void initWidget();      //初始化
	void onSelectImage();   //选择打开图片
	void onPasteImage();    //选择粘贴图片
	void onZoomInImage();   //图片放大
	void onZoomOutImage();  //图片缩小
	void onPresetImage();   //图片还原

private:
	QImage m_image;           //显示的图片
	qreal m_zoomValue = 1.0;  //鼠标缩放值
	int m_xPtInterval = 0;    //平移X轴的值
	int m_yPtInterval = 0;    //平移Y轴的值
	QPoint m_oldPos;          //旧的鼠标位置
	bool m_pressed = false;   //鼠标是否被摁压
	QString m_localFileName;  //文件名称
	QMenu* m_menu;            //右键菜单
};

#endif // PHOTOLABEL_H
```

`photolabel.cpp`：
```cpp
#include "photolabel.h"
#include <QPainter>
#include <QDebug>
#include <QWheelEvent>
#include <QFileDialog>
#include <QClipboard>
#include <QApplication>
#include <QMimeData>
#include <QFileInfo>
#include <QMessageBox>

PhotoLabel::PhotoLabel(QWidget* parent) :QLabel(parent)
{
	initWidget();
}

void PhotoLabel::initWidget()
{
	//初始化右键菜单
	m_menu = new QMenu(this);
	QAction* loadImage = new QAction;
	loadImage->setText(tr("&Open new..."));
	connect(loadImage, &QAction::triggered, this, &PhotoLabel::onSelectImage);
	m_menu->addAction(loadImage);

	QAction* pasteImage = new QAction;
	pasteImage->setText(tr("&Paste image"));
	connect(pasteImage, &QAction::triggered, this, &PhotoLabel::onPasteImage);
	m_menu->addAction(pasteImage);
	m_menu->addSeparator();

	QAction* zoomInAction = new QAction;
    zoomInAction->setText(tr("Zoom in &+"));
	connect(zoomInAction, &QAction::triggered, this, &PhotoLabel::onZoomInImage);
	m_menu->addAction(zoomInAction);

	QAction* zoomOutAction = new QAction;
    zoomOutAction->setText(tr("Zoom out &-"));
	connect(zoomOutAction, &QAction::triggered, this, &PhotoLabel::onZoomOutImage);
	m_menu->addAction(zoomOutAction);

	QAction* presetAction = new QAction;
	presetAction->setText(tr("&Reset"));
	connect(presetAction, &QAction::triggered, this, &PhotoLabel::onPresetImage);
	m_menu->addAction(presetAction);
	m_menu->addSeparator();
	/*
	QAction *clearAction = new QAction;
	clearAction->setText("Clear");
	connect(clearAction, &QAction::triggered, this, &PhotoLabel::clearShow);
	m_menu->addAction(clearAction);
	*/
}

void PhotoLabel::openFile(QString path)
{
	if (path.isEmpty())
	{
		return;
	}

	if (!m_image.load(path))
	{
		QMessageBox::warning(this, tr("Error"), tr("Cannot load file!"));
		return;
	}

	m_zoomValue = 1.0;
	m_xPtInterval = 0;
	m_yPtInterval = 0;

	m_localFileName = path;
	emit this->imageLoadSuccess();
	update();
}

void PhotoLabel::clearShow()
{
	m_localFileName = "";
	m_image = QImage();
	this->clear();
}

void PhotoLabel::setImage(QImage& img)
{
	if (img.isNull())
	{
		return;
	}

	m_zoomValue = 1.0;
	m_xPtInterval = 0;
	m_yPtInterval = 0;

	m_localFileName = "";
	m_image = img.copy(0, 0, img.width(), img.height());
	emit imageLoadSuccess();
	update();
}

void PhotoLabel::openAction()
{
	this->onSelectImage();
}

void PhotoLabel::pasteAction()
{
	this->onPasteImage();
}

const QImage& PhotoLabel::getImage()
{
	return m_image;
}

void PhotoLabel::paintEvent(QPaintEvent* event)
{
	if (m_image.isNull())
		return QWidget::paintEvent(event);

	QPainter painter(this);

	// 根据窗口计算应该显示的图片的大小
	int width = qMin(m_image.width(), this->width());
	int height = int(width * 1.0 / (m_image.width() * 1.0 / m_image.height()));
	height = qMin(height, this->height());
	width = int(height * 1.0 * (m_image.width() * 1.0 / m_image.height()));

	// 平移
	painter.translate(this->width() / 2 + m_xPtInterval, this->height() / 2 + m_yPtInterval);

	// 缩放
	painter.scale(m_zoomValue, m_zoomValue);

	// 绘制图像
	QRect picRect(-width / 2, -height / 2, width, height);
	painter.drawImage(picRect, m_image);

	QWidget::paintEvent(event);
}

void PhotoLabel::wheelEvent(QWheelEvent* event)
{
	int value = event->angleDelta().y() / 15;
	if (value < 0)  //放大
		onZoomInImage();
	else            //缩小
		onZoomOutImage();

	update();
}

void PhotoLabel::mousePressEvent(QMouseEvent* event)
{
	m_oldPos = event->pos();
	m_pressed = true;
	this->setCursor(Qt::ClosedHandCursor); //设置鼠标样式
}

void PhotoLabel::mouseMoveEvent(QMouseEvent* event)
{
	if (!m_pressed)
		return QWidget::mouseMoveEvent(event);

	QPoint pos = event->pos();
	int xPtInterval = pos.x() - m_oldPos.x();
	int yPtInterval = pos.y() - m_oldPos.y();

	m_xPtInterval += xPtInterval;
	m_yPtInterval += yPtInterval;

	m_oldPos = pos;
	update();
}

void PhotoLabel::mouseReleaseEvent(QMouseEvent*/*event*/)
{
	m_pressed = false;
	this->setCursor(Qt::ArrowCursor); //设置鼠标样式
}

void PhotoLabel::dragEnterEvent(QDragEnterEvent* event)
{
	if (event->mimeData()->hasUrls())
	{
		event->acceptProposedAction();
	}
	else
	{
		event->ignore();
	}
}

void PhotoLabel::dragMoveEvent(QDragMoveEvent* event)
{

}

void PhotoLabel::dropEvent(QDropEvent* event)
{
	QList<QUrl> urls = event->mimeData()->urls();
	if (urls.empty())
		return;

	QString fileName = urls.first().toLocalFile();
	QFileInfo info(fileName);
	if (!info.isFile())
		return;

	this->openFile(fileName);
}

void PhotoLabel::contextMenuEvent(QContextMenuEvent* event)
{
	QPoint pos = event->pos();
	pos = this->mapToGlobal(pos);
	m_menu->exec(pos);
}

void PhotoLabel::onSelectImage()
{
	QString path = QFileDialog::getOpenFileName(this, tr("Open a image file"), "./", tr("Images (*.bmp *.png *.jpg *.jpeg *.gif *.tiff)\nAll files (*.*)"));
	if (path.isEmpty())
		return;

	openFile(path);
}

void PhotoLabel::onPasteImage()
{
	QClipboard* clipboard = QApplication::clipboard();
	QImage img = clipboard->image();
	if (img.isNull())
	{
		return;
	}

	this->setImage(img);
}

void PhotoLabel::onZoomInImage()
{
	m_zoomValue += 0.05;
	update();
}

void PhotoLabel::onZoomOutImage()
{
	m_zoomValue -= 0.05;
	if (m_zoomValue <= 0)
	{
		m_zoomValue = 0.05;
		return;
	}

	update();
}

void PhotoLabel::onPresetImage()
{
	m_zoomValue = 1.0;
	m_xPtInterval = 0;
	m_yPtInterval = 0;
	update();
}
```

base64和图片转换的代码放在窗口控件的槽函数中。

`widget.cpp`：
```cpp
void Widget::updateCode() //图片数据转换成base64编码
{
	QImage image = ui->viewer->getImage();
	if (image.isNull())
	{
		QMessageBox::warning(this, tr("Error"), tr("Please load an image file!"));
		return;
	}
	QByteArray ba;
	QBuffer buf(&ba);
	image.save(&buf, format.toStdString().c_str());

	QByteArray md5 = QCryptographicHash::hash(ba, QCryptographicHash::Md5);
	QString strMd5 = md5.toHex();

	QString head_md = QString::fromUtf8("![%1](%2)");
	QString prefix = QString::fromUtf8("data:image/%1;base64,").arg(format);
	QString code = QString::fromUtf8(ba.toBase64());

	if (ui->checkBox->isChecked())
	{
		ui->textEdit->setText(head_md.arg(strMd5).arg(prefix + code));
	}
	else
	{
		ui->textEdit->setText(prefix + code);
	}

	buf.close();

	int num = ui->textEdit->toPlainText().length();
	ui->label->setText(tr("Length : ") + QString::number(num));
}


void Widget::updateImage() // base64编码转换成图片数据
{
	QString p_b = ui->textEdit->toPlainText();
	if (p_b.isEmpty())
	{
		return;
	}
	if (p_b.contains(QRegularExpression("data:image[/a-z]*;base64,")))
	{
		// 清除base64编码的html标签
		p_b = p_b.remove(QRegularExpression("data:image[/a-z]*;base64,"));
	}

	QImage image;
	if (!image.loadFromData(QByteArray::fromBase64(p_b.toLocal8Bit())))
	{
		QMessageBox::warning(this, tr("Error"), tr("Fail to decrypt codes!"));
		return;
	}
	ui->viewer->setImage(image);
}
```

### 2.2 Python实现

同样的，该软件也提供了基于Python的实现，同样通过重载QLabel实现图片显示。

`photolabel.py`：
```python
# This Python file uses the following encoding: utf-8
import sys

from PySide6.QtCore import (Qt, qDebug, QFileInfo, QMimeData, QRect, QPoint)

from PySide6.QtGui import (QAction, QImage, QAction, QDragEnterEvent, QDragMoveEvent,
                           QDropEvent, QContextMenuEvent, QPaintEvent, QMouseEvent,
                           QWheelEvent, QPainter, QClipboard, QCursor)

from PySide6.QtWidgets import (QApplication, QLabel, QMenu, QMessageBox, QFileDialog)


class PhotoLabel(QLabel):
    def __init__(self, parent):
        super().__init__(parent)
        self.m_image = QImage()  # 显示的图片
        self.m_zoomValue = 1.0  # 鼠标缩放值
        self.m_xPtInterval = 0  # 平移X轴的值
        self.m_yPtInterval = 0  # 平移Y轴的值
        self.m_oldPos = QPoint()  # 旧的鼠标位置
        self.m_pressed = False  # 鼠标是否被摁压
        self.m_localFileName = None  # 文件名称
        self.m_menu = None
        self.initial_widget()

    def initial_widget(self):
        self.m_menu = QMenu(self)
        load_image = QAction(u"&Open new...", self)
        load_image.triggered.connect(self.on_select_image)
        self.m_menu.addAction(load_image)
        paste_image = QAction(u"&Paste image", self)
        paste_image.triggered.connect(self.on_paste_image)
        self.m_menu.addAction(paste_image)
        self.m_menu.addSeparator()
        zoom_in_action = QAction(u"Zoom in &+", self)
        zoom_in_action.triggered.connect(self.on_zoom_in_image)
        self.m_menu.addAction(zoom_in_action)
        zoom_out_action = QAction(u"Zoom out &-", self)
        zoom_out_action.triggered.connect(self.on_zoom_out_image)
        self.m_menu.addAction(zoom_out_action)
        self.m_menu.addSeparator()
        preset_action = QAction(u"&Reset", self)
        preset_action.triggered.connect(self.on_preset_image)
        self.m_menu.addAction(preset_action)
        self.m_menu.addSeparator()
        # clear_action = QAction(u"&Reset", self)
        # clear_action.triggered.connect(self.clear_show)
        # self.m_menu.addAction(clear_action)

    def open_file(self, path: str):  # 打开图片文件
        if path is None:
            return
        if self.m_image.load(path) is False:
            QMessageBox.warning(self, "Error", "Cannot load file!")
            return
        self.m_zoomValue = 1.0
        self.m_xPtInterval = 0
        self.m_yPtInterval = 0
        self.m_localFileName = path
        self.update()

    def clear_show(self):  # 清空显示
        self.m_localFileName = None
        self.m_image = QImage()
        self.clear()

    def set_image(self, image: QImage):  # 设置图片
        if image is None:
            return
        self.m_zoomValue = 1.0
        self.m_xPtInterval = 0
        self.m_yPtInterval = 0
        self.m_localFileName = None
        self.m_image = image.copy(0, 0, image.width(), image.height())
        self.update()

    def open_action(self):  # 调用打开文件对话框
        self.on_select_image()

    def paste_action(self):  # 粘贴来自剪贴板的图片
        self.on_paste_image()

    def get_image(self) -> QImage:  # 调用存储的图片数据
        return self.m_image

    def contextMenuEvent(self, event: QContextMenuEvent):  # 右键菜单
        pos = event.pos()
        pos = self.mapToGlobal(pos)
        self.m_menu.exec(pos)

    def paintEvent(self, event: QPaintEvent):  # QPaint画图
        if self.m_image.isNull():
            # super().paintEvent(event)
            return
        painter = QPainter(self)
        # 根据窗口计算应该显示的图片的大小
        width = min(self.m_image.width(), self.width())
        height = int(width * 1.0 / (self.m_image.width() * 1.0 / self.m_image.height()))
        height = min(height, self.height())
        width = int(height * 1.0 * (self.m_image.width() * 1.0 / self.m_image.height()))
        # 平移
        painter.translate(self.width() / 2 + self.m_xPtInterval, self.height() / 2 + self.m_yPtInterval)
        # 缩放
        painter.scale(self.m_zoomValue, self.m_zoomValue)
        # 绘制图像
        pic_rect = QRect(int(-width / 2), int(-height / 2), width, height)
        painter.drawImage(pic_rect, self.m_image)
        # super().paintEvent(event)

    def wheelEvent(self, event: QWheelEvent):  # 鼠标滚轮滚动
        value = int(event.angleDelta().y() / 15)
        if value < 0:  # 放大
            self.on_zoom_in_image()
        else:  # 缩小
            self.on_zoom_out_image()
        self.update()

    def mousePressEvent(self, event: QMouseEvent):  # 鼠标摁下
        self.m_oldPos = event.pos()
        self.m_pressed = True
        self.setCursor(Qt.ClosedHandCursor)  # 设置鼠标样式

    def mouseMoveEvent(self, event: QMouseEvent):  # 鼠标松开
        if self.m_pressed is False:
            # super().mouseMoveEvent(event)
            return
        pos = event.pos()
        xp = pos.x() - self.m_oldPos.x()
        yp = pos.y() - self.m_oldPos.y()
        self.m_xPtInterval += xp
        self.m_yPtInterval += yp
        self.m_oldPos = pos
        self.update()

    def mouseReleaseEvent(self, event: QMouseEvent):  # 鼠标发射事件
        self.m_pressed = False
        self.setCursor(Qt.ArrowCursor)  # 设置鼠标样式

    # 拖放文件
    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
        else:
            event.ignore()

    def dragMoveEvent(self, event: QDragMoveEvent):
        pass

    def dropEvent(self, event: QDropEvent):
        urls = event.mimeData().urls()
        if urls is None:
            return
        file_name = urls[0].toLocalFile()
        info = QFileInfo(file_name)
        if info.isFile() is False:
            return
        self.open_file(file_name)

    def on_select_image(self):  # 选择打开图片
        path, _ = QFileDialog.getOpenFileName(self,
                                              "Open a image file", "./",
                                              "Images (*.bmp *.png *.jpg *.jpeg *.gif *.tiff)\nAll files (*.*)")
        if path is None:
            return
        info = QFileInfo(path)
        if info.isFile() is False:
            return
        self.open_file(path)

    def on_paste_image(self):  # 选择粘贴图片
        clipboard = QApplication.clipboard()
        img = clipboard.image()
        if img.isNull():
            return
        self.set_image(img)

    def on_zoom_in_image(self):  # 图片放大
        self.m_zoomValue += 0.05
        self.update()

    def on_zoom_out_image(self):  # 图片缩小
        self.m_zoomValue -= 0.05
        if self.m_zoomValue <= 0:
            self.m_zoomValue = 0.05
            return
        self.update()

    def on_preset_image(self):  # 图片还原
        self.m_zoomValue = 1.0
        self.m_xPtInterval = 0
        self.m_yPtInterval = 0
        self.update()


if __name__ == "__main__":
    pass
```

值得注意的是，python实现代码中，二进制数据到base64的转换是通过ptyhon的str函数完成的，因此输出字符串会包含`b'...'`的标签，需要通过字符串切片去除该标签。
`widget.py`：
```python
def update_code(self): #图片→base64
        image = self.ui.viewLabel.get_image()
        if image.isNull():
            QMessageBox.warning(self, "Error", "Please load an image file!")
            return
        ba = QByteArray()
        buf = QBuffer(ba)
        image.save(buf, self.m_format)
        md5 = QCryptographicHash.hash(ba, QCryptographicHash.Md5)
        strMd5 = str(md5.toHex())[2:-1]
        prefix = "data:image/{};base64,".format(self.m_format)
        code = str(ba.toBase64())[2:-1]
        if self.ui.checkBox.isChecked():
            self.ui.textEdit.setText("![{0}]({1})".format(strMd5, prefix + code))
        else:
            self.ui.textEdit.setText(prefix + code)
        buf.close()
        num = len(self.ui.textEdit.toPlainText())
        self.ui.lengthLabel.setText("Length : " + str(num))

    def update_image(self): #base64→图片
        p_b = self.ui.textEdit.toPlainText()
        if len(p_b) == 0:
            return
        if re.match("data:image[/a-z]*;base64,", p_b):
            p_b = re.sub("data:image[/a-z]*;base64,", "", p_b, count=1)
        image = QImage()
        if image.loadFromData(QByteArray.fromBase64(p_b.encode())) is False:
            QMessageBox.warning(self, "Error", "Fail to decrypt codes!")
            return
        self.ui.viewLabel.set_image(image)
```

UI均通过QtDesigner实现，无论C++实现还是Python实现，软件界面效果均一致。

[^1]: [Base64](https://zh.wikipedia.org/wiki/Base64)

[^2]: [15、Qt显示图片并支持缩放、移动等操作](https://blog.csdn.net/Viciower/article/details/135146355)