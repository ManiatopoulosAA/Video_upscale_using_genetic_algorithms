clear
clc
close all;

tic

%frame reading
srcFiles=dir('D:\MATLAB FILES\VideoUpscale\superresvideo\scene\*.jpeg');  % the folder in which your images exists
source_filename0=strcat('scene\',srcFiles(1).name);
R0=imread(source_filename0);
output_filename0=strcat('D:\MATLAB FILES\VideoUpscale\superresvideo\scene2\',srcFiles(1).name); %the folder where you want the images to be saved
imwrite(R0,output_filename0);

[s1,s2,~]=size(R0);

x_center=s1;
y_center=s2;

dx=zeros(1,16);
dy=zeros(1,16);

frame=zeros(270,480,3,16); %example sizes
final_frame_small=zeros(540,960,3);

frame_len=length(srcFiles);

fft_Ik=zeros(539,959,16);

for num=10:frame_len-10
    disp(num-9);
    
    R0=imread(strcat('scene\',srcFiles(1+num).name));
    I0=rgb2gray(R0);
    frame_len=length(srcFiles);
    BW1=edge(I0,'Sobel');
    fft_I0=conj(fft2(BW1,2*s1-1,2*s2-1));
    
    for i=1:16
        filenamek=strcat('scene\',srcFiles(num-8+i).name);
        Rk=imread(filenamek);
        
        Ik=rgb2gray(Rk);
        BW2=edge(Ik,'Sobel');
        fft_Ik=fft2(BW2,2*s1-1,2*s2-1);
        
        C=(fft_I0.*fft_Ik)./(abs(fft_I0.*fft_Ik));
        C_inv=256*ifft2(C,'symmetric');
        
        maxim=max(max(C_inv));
        for k=1:2*s1-1
            for l=1:2*s2-1
                if C_inv(k,l)==maxim
                    m1=k;
                    m2=l;
                end
            end
        end
        dx(i)=m1-x_center;
        dy(i)=m2-y_center;
        
        newIk=circshift(Rk,[-dx(i) -dy(i)]);
        
        frame(:,:,:,i)=newIk;
    end
    
    final_frame_serial=zeros(1080,1920,3);
    
    for i=1:4:1080
        for j=1:4:1920
            for k=1:4
                for l=1:4
                    final_frame_serial(i+k-1,j+l-1,:)=frame((i+3)/4,(j+3)/4,:,(k-1)*4+l);
                end
            end
        end
    end
    
    final_frame_serial=uint8(final_frame_serial);
    imshow(final_frame_serial);
    
    final_frame_gray=rgb2gray(final_frame_serial);
    sobel_best=edge(final_frame_gray,'Sobel');
    
    d_sobel=double(sobel_best);
    
    cost_best=sum(sum(d_sobel));
    frame_best=final_frame_serial;
    
    test_frame=zeros(1080,1920,3);
    frame_suffle=zeros(270,480,3,16);
    
    for frame_ind=1:24 %24 genetic permutations
        random=randperm(16);
        frame_suffle=frame(:,:,:,random);
        for i=1:4:1080
            for j=1:4:1920
                for k=1:4
                    for l=1:4
                        test_frame(i+k-1,j+l-1,:)=frame_suffle((i+3)/4,(j+3)/4,:,(k-1)*4+l);
                    end
                end
            end
        end
        
        test_frame=uint8(test_frame);
        test_frame_gray=rgb2gray(test_frame);
        sobel_test=edge(test_frame_gray,'Sobel');
        
        d_sobel_try=double(sobel_test);
        cost=sum(sum(d_sobel_try));
        
        if cost<cost_best
            cost_best=cost;
            frame_best=test_frame;
            imshow(test_frame);
            disp(frame_ind);
            disp(cost);
        end
        
    end
    
    J1 = medfilt2(frame_best(:,:,1),[4 4]);
    J2 = medfilt2(frame_best(:,:,2),[4 4]);
    J3 = medfilt2(frame_best(:,:,3),[4 4]);
    Smoothed_frame(:,:,1)=J1;
    Smoothed_frame(:,:,2)=J2;
    Smoothed_frame(:,:,3)=J3;
    
    imshow(Smoothed_frame);
    final_frame=imresize(R0,[1080 1920],'nearest');
    final_frame(10:1070,10:1910,:)=Smoothed_frame(10:1070,10:1910,:);
    
    k=0;
    for i=1:2:1080
        k=k+1;
        l=0;
        for j=1:2:1920
            l=l+1;
            temp1=reshape(final_frame(i:i+1,j:j+1,1),[1 4]);
            temp2=reshape(final_frame(i:i+1,j:j+1,2),[1 4]);
            temp3=reshape(final_frame(i:i+1,j:j+1,3),[1 4]);
            final_frame_small(k,l,1)=median(temp1);
            final_frame_small(k,l,2)=median(temp2);
            final_frame_small(k,l,3)=median(temp3); 
        end
    end
    
    final_frame_small=uint8(final_frame_small);
    frame_upscaled=imsharpen(final_frame_small, 'Radius',2,'Amount',1);
    
    imshow(frame_upscaled);
    
    imwrite(frame_upscaled,strcat('D:\MATLAB FILES\VideoUpscale\superresvideo\scene2\',srcFiles(1+num).name)); %where the new images will be written
end
toc