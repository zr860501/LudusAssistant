package com.ludusassistant.app.vision;
import android.graphics.Bitmap;
import android.media.Image;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;
/** Fast OCR: 540px working width, one primary recognizer, fallback only on failure, single in-flight request. */
public final class OcrEngine implements AutoCloseable {
 public static final class Result{public final String text;public final float confidence;public final int width,height;public final List<OcrToken> tokens;Result(String t,float c,int w,int h,List<OcrToken> x){text=t==null?"":t;confidence=c;width=w;height=h;tokens=x==null?java.util.Collections.emptyList():java.util.Collections.unmodifiableList(x);}}
 private final TextRecognizer primary=TextRecognition.getClient(new ChineseTextRecognizerOptions.Builder().build());
 private final TextRecognizer latin=TextRecognition.getClient(com.google.mlkit.vision.text.latin.TextRecognizerOptions.DEFAULT_OPTIONS);
 private final AtomicBoolean busy=new AtomicBoolean(false);
 public boolean submit(Image image,BiConsumer<Result,Exception> callback){
  if(image==null||!busy.compareAndSet(false,true))return false; final Bitmap bitmap;
  try{bitmap=toWorkBitmap(image);}catch(Exception e){busy.set(false);if(callback!=null)callback.accept(null,e);return false;}
  final InputImage input=InputImage.fromBitmap(bitmap,0);
  primary.process(input).addOnSuccessListener(r->finish(bitmap,r,callback,null)).addOnFailureListener(err->latin.process(input).addOnSuccessListener(r->finish(bitmap,r,callback,null)).addOnFailureListener(e->finish(bitmap,null,callback,e))).addOnCompleteListener(t->busy.set(false));
  return true;
 }
 private void finish(Bitmap bitmap,Text result,BiConsumer<Result,Exception> callback,Exception error){try{if(callback==null)return;if(error!=null||result==null){callback.accept(null,error==null?new IllegalStateException("OCR returned no result"):error);return;}callback.accept(new Result(result.getText(),averageConfidence(result),bitmap.getWidth(),bitmap.getHeight(),extractTokens(result)),null);}finally{bitmap.recycle();}}
 private static List<OcrToken> extractTokens(Text result){List<OcrToken> out=new ArrayList<>();for(Text.TextBlock b:result.getTextBlocks())for(Text.Line l:b.getLines())for(Text.Element e:l.getElements()){android.graphics.Rect r=e.getBoundingBox();if(r==null)continue;Float c=e.getConfidence();out.add(new OcrToken(e.getText(),c==null?0.5f:c,r.left,r.top,r.right,r.bottom));}return out;}
 private static float averageConfidence(Text result){float sum=0f;int n=0;for(Text.TextBlock b:result.getTextBlocks())for(Text.Line l:b.getLines())for(Text.Element e:l.getElements()){Float c=e.getConfidence();if(c!=null&&c>=0f){sum+=c;n++;}}return n==0?0.5f:sum/n;}
 private static Bitmap toWorkBitmap(Image image){if(image.getFormat()!=android.graphics.PixelFormat.RGBA_8888||image.getPlanes().length==0)throw new IllegalArgumentException("Unsupported capture image format: "+image.getFormat());Image.Plane p=image.getPlanes()[0];ByteBuffer buffer=p.getBuffer();int w=image.getWidth(),h=image.getHeight(),ps=p.getPixelStride(),rs=p.getRowStride();int pad=Math.max(0,rs-ps*w);Bitmap padded=Bitmap.createBitmap(w+pad/Math.max(1,ps),h,Bitmap.Config.ARGB_8888);buffer.rewind();padded.copyPixelsFromBuffer(buffer);Bitmap cropped=padded.getWidth()==w?padded:Bitmap.createBitmap(padded,0,0,w,h);if(cropped!=padded)padded.recycle();int maxW=540;if(cropped.getWidth()<=maxW)return cropped;int nh=Math.max(1,Math.round(cropped.getHeight()*(maxW/(float)cropped.getWidth())));Bitmap scaled=Bitmap.createScaledBitmap(cropped,maxW,nh,true);cropped.recycle();return scaled;}
 @Override public void close(){primary.close();latin.close();}
}
